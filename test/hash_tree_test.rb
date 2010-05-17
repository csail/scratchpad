require 'helper.rb'

class HashTreeTest < Test::Unit::TestCase
  Crypto = Scratchpad::Crypto
  HashTree = Scratchpad::HashTree
  
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
    assert_equal "fa81d8ea92da5b63ae58cba7cb972f3f3a2fabee",
                 @tree[1].unpack('H*').first
  end
  
  def test_leaf_validation_path
    assert_equal Set.new([1, 2, 3, 4, 5, 10, 11, 22, 23, 46, 47, 94, 95,
                          190, 191, 380, 381, 762, 763, 1524, 1525]),
                 @tree.leaf_validation_path(500)
  end

  def test_update
    @tree.update 500, one_block_hash
    @tree.verify
    assert_equal "67e03a78785a9dddb888a989840d839de92a5ea4",
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