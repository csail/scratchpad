require File.expand_path('../helper.rb', __FILE__)

class HashTreeCacheDriverTest < Test::Unit::TestCase
  Crypto = Scratchpad::Crypto
  HashTree = Scratchpad::HashTree
  HashTreeCache = Scratchpad::HashTreeCache
  HashTreeCacheDriver = Scratchpad::HashTreeCacheDriver
  
  def setup
    @tree = HashTree.empty_tree 1000, empty_block_hash
    @cache = HashTreeCache.new 64, @tree.root_hash, @tree.leaf_count
    @driver = HashTreeCacheDriver.new @tree, @cache.entry_count
  end
  
  def empty_block_hash
    @empty_block_hash ||= Crypto.crypto_hash("\0" * 64 * 1024)
  end
  
  def one_block_hash
    @one_block_hash ||= Crypto.crypto_hash("1" * 64 * 1024)    
  end
  
  def apply_ops(ops)
    ops.each do |op|
      case op[:op]
      when :load
        @cache.load_entry op[:line], op[:node], @tree[op[:node]],
                          op[:old_parent_line]
      when :verify
        @cache.verify_children op[:parent], op[:left], op[:right]
      end
    end
    @driver.perform_ops ops
  end
  
  def check_read_ops(leaf_id)
    load_data = @driver.load_leaf leaf_id
    apply_ops load_data[:ops]
    leaf_id = @tree.leaf_node_id(leaf_id)
    assert_nothing_raised "Leaf #{leaf_id} content validation failed" do
      @cache.check_hash load_data[:line], leaf_id, @tree[leaf_id]
    end
    load_data[:ops]
  end
  
  def check_update_ops(leaf_id)
    update_data = @driver.load_update_path leaf_id
    apply_ops update_data[:ops]
    assert_nothing_raised "Leaf #{leaf_id} content udpdate failed" do
      @cache.update_leaf_value update_data[:path], one_block_hash
    end
    update_data[:ops]
  end
  
  def test_one_read
    check_read_ops 500
  end
  
  def test_one_update
    check_update_ops 500
  end
  
  def test_adjacent_reads
    check_read_ops 500
    ops = check_read_ops 501
    
    assert_equal 0, ops.length, 'Adjacent reads should not require extra ops'
  end

  def test_adjacent_updates
    check_update_ops 500
    ops = check_update_ops 501
    
    assert_equal 0, ops.length, 'Adjacent updates should not require extra ops'
  end
  
  def test_nearby_reads
    check_read_ops 500
    ops = check_read_ops 504
    
    assert_operator ops.length, :<=, 10, 'Nearby reads should require few ops' 
  end
end
