require File.expand_path('../helper.rb', __FILE__)

class HashTreeOnDiskTest < Test::Unit::TestCase
  Crypto = Scratchpad::Crypto
  Disk = Scratchpad::Models::Disk
  HashTree = Scratchpad::HashTree
  
  
  def setup
    @min_leaf_count = 1000
    @tree = HashTree.empty_tree @min_leaf_count, empty_block_hash
    @disk = Disk.empty_disk 4096, :block_count => @min_leaf_count
  end
  
  def empty_block_hash
    @empty_block_hash ||= Crypto.crypto_hash("\0" * 64 * 1024)
  end
  
  def one_block_hash
    @one_block_hash ||= Crypto.crypto_hash("1" * 64 * 1024)    
  end

  def test_serialization
    @tree.update 500, one_block_hash
    @tree.write_to_disk @disk, 1
    
    empty_block  = "\0" * @disk.block_size
    (1 + @tree.blocks_on_disk(@disk)).upto(@disk.block_count - 1) do |block|
      assert_equal empty_block, @disk.read_blocks(block, 1),
                   'write_to_disk wrote past the advertised tree size'
    end
    
    @tree = HashTree.from_disk @disk, @min_leaf_count, 1
    assert_equal '1a9934f73d2ddf275d5e9080d8f7dab43f6add4e',
                 @tree[1].unpack('H*').first,
                 'Root node not restored correctly'
    assert_equal @tree[@tree.leaf_node_id(500)], @one_block_hash,
                 'Leaf node not restored correctly'
  end
end
