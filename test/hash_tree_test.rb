require 'helper.rb'

class HashTreeTest < Test::Unit::TestCase
  Crypto = Scratchpad::Crypto
  HashTree = Scratchpad::HashTree
  include HashTree::Exceptions
  
  
  def setup
    @tree = HashTree.new 1000, empty_block_hash
  end
  
  def empty_block_hash
    @empty_block_hash ||= Crypto.crypto_hash("\0" * 64 * 1024)
  end
  
  def one_block_hash
    @one_block_hash ||= Crypto.crypto_hash("1" * 64 * 1024)    
  end
  
  def test_leaf_count
    [[1, 1], [2, 2], [1000, 1024], [1024, 1024]].each do |input, golden|
      tree = HashTree.new input, empty_block_hash
      assert_equal golden, tree.leaf_count,
                   "Incorrect leaf count for #{input} min-leaves"
    end
  end
  
  def test_root_hash
    assert_equal 'fa81d8ea92da5b63ae58cba7cb972f3f3a2fabee',
                 @tree[1].unpack('H*').first
  end
  
  def test_invalid_accesses
    assert_raise(InvalidNodeId, "0") { @tree[0] }
    assert_raise(InvalidNodeId, "-1") { @tree[-1] }
    assert_raise(InvalidNodeId, "2048") { @tree[2048] }
    assert_raise(InvalidNodeId, "2049") { @tree[2049] }
  end
  
  def test_leaf_update_path
    golden_path = [1524, 1525, 762, 763, 381, 380, 190, 191, 95, 94, 47, 46,
                   23, 22, 11, 10, 5, 4, 2, 3, 1]
    assert_equal golden_path, @tree.leaf_update_path(500)
  end

  def test_update
    @tree.update 500, one_block_hash
    @tree.verify
    assert_equal '1a9934f73d2ddf275d5e9080d8f7dab43f6add4e',
                 @tree[1].unpack('H*').first
  end
  
  def test_verify
    assert_nothing_raised("Initial tree should be fine") { @tree.verify }
    
    # TODO(costan): rewrite this using serialization once that's nailed down
    @tree.instance_variable_get(:@nodes)[1524] = one_block_hash
    assert_raise RuntimeError, "Compromised tree should not verify" do
      @tree.verify
    end
  end
end
