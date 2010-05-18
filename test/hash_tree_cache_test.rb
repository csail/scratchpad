require 'helper.rb'

class HashTreeCacheTest < Test::Unit::TestCase
  Crypto = Scratchpad::Crypto
  HashTree = Scratchpad::HashTree
  HashTreeCache = Scratchpad::HashTreeCache
  include Scratchpad::HashTreeCache::Exceptions
  
  def setup
    @tree = HashTree.new 1000, empty_block_hash
    @cache = HashTreeCache.new 64, @tree.root_hash, @tree.leaf_count

    @cache.load_entry 1, 2, @tree[2], -1
    @cache.load_entry 2, 3, @tree[3], -1
  end
  
  def empty_block_hash
    @empty_block_hash ||= Crypto.crypto_hash("\0" * 64 * 1024)
  end
  
  def one_block_hash
    @one_block_hash ||= Crypto.crypto_hash("1" * 64 * 1024)    
  end
  
  def test_root_hash
    assert_equal @tree.root_hash, @cache.root_hash
  end
  
  def test_check_hash
    assert_equal @cache, @cache.check_hash(0, 1, @tree.root_hash),
                 "should work for an untouched root node"
    assert_raise IncorrectNodeHash, "should catch incorrect hash" do
      @cache.check_hash 0, 1, @tree[2]
    end
    assert_raise IncorrectNodeHash, "should catch incorrect node number" do
      @cache.check_hash 0, 2, @tree.root_hash
    end
    assert_raise UnverifiedEntry, "should catch unverified entry" do
      @cache.check_hash 1, 2, @tree[2]
    end
  end
  
  def test_verify_children_correctly
    assert_nothing_raised do
      @cache.verify_children 0, 1, 2
      @cache.check_hash 1, 2, @tree[2]
      @cache.check_hash 2, 3, @tree[3]
    end
  end
  
  def test_double_verify_children_correctly
    @cache.verify_children 0, 1, 2
    @cache.check_hash 1, 2, @tree[2]
    
    assert_nothing_raised "left child reloaded" do      
      @cache.load_entry 1, 2, @tree[2], 0
      @cache.verify_children 0, 1, 2
    end
    
    assert_nothing_raised "right child reloaded" do
      @cache.load_entry 2, 3, @tree[3], 0
      @cache.verify_children 0, 1, 2
    end
    
    assert_nothing_raised "both children reloaded" do
      @cache.load_entry 1, 2, @tree[2], 0
      @cache.load_entry 2, 3, @tree[3], 0
      @cache.verify_children 0, 1, 2      
    end
  end
  
  def test_load_entry_with_wrong_old_parent_entry
    @cache.verify_children 0, 1, 2
    assert_raise(InvalidUpdatePath) { @cache.load_entry 1, 4, @tree[3], 2 }
  end
  
  def test_load_entry_with_valid_children
    @cache.verify_children 0, 1, 2
    @cache.load_entry 3, 4, @tree[4], 1
    @cache.load_entry 4, 5, @tree[5], 1
    @cache.verify_children 1, 3, 4
    
    assert_raise(DuplicateChild) { @cache.load_entry 1, 2, @tree[2], 0 }
  end
  
  def test_verify_children_with_bad_data
    @cache.load_entry 1, 2, @tree[3], 0    
    assert_raise(IncorrectNodeHash) { @cache.verify_children 0, 1, 2 }
  end
  
  def test_verify_children_with_double_left_child
    @cache.verify_children 0, 1, 2
    @cache.load_entry 3, 2, @tree[2], -1
    assert_raise(DuplicateChild) { @cache.verify_children 0, 3, 2 }
  end

  def test_verify_children_with_double_right_child
    @cache.verify_children 0, 1, 2
    @cache.load_entry 3, 3, @tree[3], -1
    assert_raise(DuplicateChild) { @cache.verify_children 0, 1, 3 }
  end
end
