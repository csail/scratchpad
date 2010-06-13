# :nodoc: namespace
module Scratchpad

# Common code for all disk drivers.
module DiskHelper
  # Reads data from this disk.
  #
  # Args:
  #   start_block:: the first block to be read (0-based)
  #   block_count:: the number of blocks to be read
  #
  # Returns a string of block_count * block_size bytes.
  def read_blocks(start_block, block_count)
    check_bounds start_block, block_count
    read_blocks_without_checks start_block, block_count
  end
  
  # Writes data to this disk.
  #
  # Args:
  #   start_block:: the first block to be written (0-based)
  #   block_count:: the number of blocks to be written
  #   data:: the contents of the blocks to be written; should be a String of
  #          exactly block_count * block_size bytes
  #
  # The return value is undefined. Raises an exception if something goes wrong.
  def write_blocks(start_block, block_count, data)
    check_bounds start_block, block_count
    write_blocks_without_checks start_block, block_count, data
  end
  
  # Formats a disk.  
  #
  # This operation zeroes out the disk, and creates a hash tree to support
  # integrity checking.
  #
  # Returns self.
  def format
    empty_block = self.empty_block
    hash_tree = HashTree.empty_tree leaf_count, Crypto.crypto_hash(empty_block)
    hash_tree.write_to_disk self, 2
    hash_tree_blocks = hash_tree.blocks_on_disk self
    (2 + hash_tree_blocks).upto(block_count - 1) do |block|
      self.write_blocks block, 1, empty_block
    end
    self
  end
  
  # Reads the hash tree supporting integrity checking on this disk.
  #
  # Returns a HashTree instance.
  def read_hash_tree
    HashTree.from_disk self, leaf_count, 2
  end
  
  # Minimum number of leaves in the hash tree used to authenticate the disk. 
  def leaf_count
    block_count - 2
  end
  
  def write_manufacturing_state(state)
    write_blocks 0, 1, pad_to_block_size(state[:puf_syndrome])
    write_blocks 1, 1,
                 pad_to_block_size(Crypto.save_cert(state[:endorsement_cert]))
  end
  
  def manufacturing_state
    {
      :puf_syndrome => data_from_padded_block(read_blocks(0, 1)),
      :endorsement_cert => Crypto.load_cert(
          data_from_padded_block(read_blocks(1, 1)))
    }
  end
  
  # The number of initial blocks used for bookkeeping. 
  def header_blocks
    2 + HashTree.blocks_on_disk(self, leaf_count)
  end
    
  # Returns the given data, padded to match the size of the disk's block.
  def pad_to_block_size(data)
    data = [data.length].pack('N') + data
    return data if data.length % block_size == 0
    data + "\0" * (block_size - data.length % block_size)
  end
  private :pad_to_block_size
  
  # Retrieves data previously padded by a call to pad_to_block_size.
  def data_from_padded_block(block)
    length = block[0, 4].unpack('N').first
    block[4, length]
  end
  private :data_from_padded_block
    
  
  # Raises an exception if a read-write operation would go out of bounds.
  #
  # Args:
  #   start_block:: the first block in the read/write operation (0-based)
  #   block_count:: the number of blocks in the read/write operation
  def check_bounds(start_block, block_count)
    raise "Negative starting block" if start_block < 0
    raise "Non-positive block count" if block_count <= 0
    raise "Out of bounds" if self.block_count < start_block + block_count    
  end
  private :check_bounds
  
  # The contents of an uninitialized block.
  def empty_block
    "\0" * block_size
  end
end  # module Scratchpad::DiskHelper

end  # namespace Scratchpad
