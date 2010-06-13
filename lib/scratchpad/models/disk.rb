# :nodoc: namespace
module Scratchpad

# :nodoc: namespace
module Models


# Untrusted disk model.
#
# This is supposed to be an interface on top of a real hard disk. It translates
# between the disk's native block size (usually around 1-4kb) and the
# application-desired block size (usually around 1Mb).
#
# TODO(costan): Merkle tree storage should also happen here
class Disk
  include Scratchpad::DiskHelper
  
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
  
  # The number of blocks available on the disk.
  def block_count
    @block_count
  end
  
  # The size of a disk block. All transfers work on blocks.
  def block_size
    @block_size
  end

  # Reads data from this disk, without verifying the arguments' correctness.
  #
  # This method should only be called by read_blocks. A disk driver should
  # implement this method instead of read_blocks.
  def read_blocks_without_checks(start_block, block_count)
    @blocks[start_block, block_count].map { |block| block || empty_block }.join    
  end
  private :read_blocks_without_checks
    
  # Writes data to this disk, without verifying the arguments' correctness.
  #
  # This method should only be called by write_blocks. A disk driver should
  # implement this method instead of write_blocks.
  def write_blocks_without_checks(start_block, block_count, data)
    raise "Wrong data buffer size" if data.length != block_count * block_size
    0.upto(block_count - 1) do |i|
      @blocks[start_block + i] = data[i * block_size, block_size]
    end    
  end
  private :write_blocks_without_checks    
end  # class Scratchpad::Models::Disk

end  # namespace Scratchpad::Models

end  # namespace Scratchpad
