# :nodoc: namespace
module Scratchpad


# Model for the high-performance trusted storage client.
class Client
  # Creates a new client session to the given server.
  def initialize(server)    
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
  # Returns a string with the opeartion
  def read_blocks(start_block, block_count)
  end
  
  def write_blocks(start_block, block_count, data)
  end
end  # class Scratchpad::Client

end  # namespace Scratchpad
