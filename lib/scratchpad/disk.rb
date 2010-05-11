# :nodoc: namespace
module Scratchpad


# Untrusted disk model.
#
# This is supposed to be an interface on top of a real hard disk. It translates
# between the disk's native block size (usually around 1-4kb) and the
# application-desired block size (usually around 1Mb).
#
# TODO(costan): Merkle tree storage should also happen here
class Disk
  # Creates a new disk model.
  #
  # Args:
  #   block_size:: the application-desired block size, in bytes
  #   options:: a Symbol-indexed Hash with model-dependent options; the
  #             RAM-backed disk model takes :block_count as an argument
  def initialize(block_size, options = {})
    @block_size = block_size
    @block_count = options[:block_count] || 1024
    @blocks = Array.new(@block_count)
  end
  
  def block_count
    @block_count
  end
  
  def block_size
    @block_size
  end
  
  def read_blocks(start_block, block_count)
    check_bounds start_block, block_count
    @blocks[start_block, block_count].join
  end
  
  def write_blocks(start_block, block_count, data)
    check_bounds start_block, block_count
    raise "Wrong data buffer size" if data.length != block_count * block_size
    0.upto(block_count - 1) do |block|
      @blocks[start_block + block] = data[block_size * (start_block + i), block_size]
    end      
  end
  
  # Raises an exception if a read-write operation would go out of bounds.
  #
  # Args:
  #   start_block:: the first block in the read-write operation (0-based)
  #   block_count:: the number of blocks in the read_write operation
  def check_bounds(start_block, block_count)
    raise "Negative starting block" if start_block < 0
    raise "Non-positive block count" if block_count <= 0
    raise "Out of bounds" if @block_count < start_block + block_count    
  end
  private :check_bounds
end  # class Scratchpad::Disk

end  # namespace Scratchpad
