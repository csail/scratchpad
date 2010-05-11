# :nodoc: namespace
module Scratchpad

# :nodoc: namespace
module Models


# Model for the high-performance trusted storage client.
class Client
  # Creates a new client session to the given server.
  def initialize(server, options = {})    
    @server = server
    # TODO(costan): verify server certificate, create symmetric key
  end
    
  # The size of a storage block. Operations are atomic at the block level.
  def block_size
  end

  # The number of blocks available on this server.
  def block_count
  end
  
  # Read operation.
  #
  # Args:
  #   start_block:: the first block in the read-write operation (0-based)
  #   block_count:: the number of blocks in the read_write operation
  #
  # Returns a string with the read result. The string should have block_count *
  # block_size bytes.
  #
  # Raises an exception if something goes wrong. 
  def read_blocks(start_block, block_count)
  end
  
  # Write operation.
  #
  # Args:
  #   start_block:: the first block in the read-write operation (0-based)
  #   block_count:: the number of blocks in the read_write operation
  #   data:: the data to be written; should be a String of exactly block_count *
  #          block_size bytes
  #
  # The return value is unspecified.
  #
  # Raises an exception if something goes wrong.
  def write_blocks(start_block, block_count, data)
  end
end  # class Scratchpad::Models::Client

end  # namespace Scratchpad::Models

end  # namespace Scratchpad
