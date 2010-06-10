require File.expand_path('../helper.rb', __FILE__)

class HashTreeCacheTest < Test::Unit::TestCase
  Crypto = Scratchpad::Crypto
  HashTree = Scratchpad::HashTree
  HashTreeCache = Scratchpad::HashTreeCache
  include HashTree::Exceptions
  include HashTreeCache::Exceptions
  
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
  
  def test_entry_count
    assert_equal 64, @cache.entry_count
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
  
  def test_load_entry_with_invalid_entry
    assert_raise(InvalidEntry) { @cache.load_entry 64, 2, @tree[2], -1 }    
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
  
  def test_load_entry_with_bogus_nodes
    assert_raise(InvalidNodeId) { @cache.load_entry 1, 0, @tree[2], 0 }
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
    
  def test_verify_children_with_bogus_left_child
    @cache.load_entry 1, 3, @tree[3], 0
    assert_raise(InvalidUpdatePath) { @cache.verify_children 0, 1, 2 }
  end

  def test_verify_children_with_bogus_right_child
    @cache.load_entry 2, 2, @tree[2], 0
    assert_raise(InvalidUpdatePath) { @cache.verify_children 0, 1, 2 }
  end

  def setup_leaf_update(node_id)
    update_nodes = @tree.leaf_update_path node_id
    update_nodes.reverse!.each_with_index do |node, entry|
      next if entry == 0
      parent_entry = entry - 2 + entry % 2
      @cache.load_entry entry, node, @tree[node], parent_entry
      if entry % 2 == 0
        if update_nodes[entry - 1] < update_nodes[entry]
          @cache.verify_children parent_entry, entry - 1, entry
        else
          @cache.verify_children parent_entry, entry, entry - 1
        end
      end
    end
    (0...(update_nodes.length)).to_a.reverse
  end
  
  def test_update_leaf_correctly
    update_path = setup_leaf_update 500
    assert_equal @cache, @cache.update_leaf_value(update_path, one_block_hash),
                 'Update path with correct pre-conditions'
    @tree.update 500, one_block_hash
    assert_equal @tree.root_hash.unpack('H*').first,
                 @cache.root_hash.unpack('H*').first, 'Incorrect root hash'
  end
  
  def test_update_leaf_with_bad_paths
    update_path = setup_leaf_update 500

    assert_raise InvalidUpdatePath, 'Starting node is not a leaf' do
      @cache.update_leaf_value update_path[2..-1], one_block_hash
    end
    assert_raise InvalidUpdatePath, 'End node is not the root' do
      @cache.update_leaf_value update_path[0...-1], one_block_hash
    end

    update_path_dup = update_path.dup
    update_path_dup[2, 2] = update_path_dup[2, 2].reverse
    assert_raise InvalidUpdatePath, 'Parent / child mismatch' do
      @cache.update_leaf_value update_path_dup, one_block_hash
    end

    update_path_dup = update_path.dup
    update_path_dup[1] = update_path_dup[2]
    assert_raise InvalidUpdatePath, 'Neighbor mismatch' do
      @cache.update_leaf_value update_path_dup, one_block_hash
    end
  end
  
  def test_update_leaf_with_unverified_nodes
    update_path = setup_leaf_update 500
    update_nodes = @tree.leaf_update_path 500
    
    update_path[0...-1].each_index do |i|
      @cache.load_entry 63, update_nodes[i], @tree[update_nodes[i]], -1
      old_value, update_path[i] = update_path[i], 63
      assert_raise UnverifiedEntry, "Unverified path element #{i}" do
        @cache.update_leaf_value update_path, one_block_hash
      end
      update_path[i] = old_value
    end
  end
end
