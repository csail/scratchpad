# :nodoc: namespace
module Scratchpad

# :nodoc: namespace
module Models


# Model for the high-performance trusted storage server.
class Server
  # 
  def initialize(fpga, disk, options = {})    
    @fpga = fpga
    @disk = disk

    @ecert = fpga.endorsement_certificate
  end
  
  # Endorsement Certificate for the FPGA on the server.
  #
  # Returns a
  def endorsement_certificate
    @ecert
  end
  
  # Creates a session with a client.
  #
  # Args:
  #   encrypted_session_key:: the client-generated symmetric session key,
  #                           encrypted under the server's public
  #                           Endorsement Key
  #
  # Returns a Server::Session object.
  def session(encrypted_session_key)
    sid = 0  # TODO(costan): FPGA session allocation
    Session.new @fpga, @disk, sid, encrypted_session_key
  end
end  # class Scratchpad::Server

# :nodoc: namespace
class Server

# A session between a trusted-storage server and a client.
class Session  
  def initialize(fpga, disk, sid, encrypted_session_key, options = {})
    @fpga = fpga
    @disk = disk
    @sid = sid    
  end
  
  # Read operation.
  #
  # Args:
  #   start_block:: the first block in the read-write operation (0-based)
  #   block_count:: the number of blocks in the read_write operation
  #   nonce:: short random string that prevents replay attacks
  #
  # Returns a Hash with the following keys:
  #   :data:: the result of the read
  #   :hmacs:: an array of HMACs, one per block, for the read results
  #
  # Raises an exception if something goes wrong. 
  def read_blocks(start_block, block_count, nonce)
    # TODO(costan): Merkle tree stuff
    
    data = @disk.read_blocks start_block, block_count
    hmacs = (0...block_count).map do |i|
      @fpga.hmac start_block + i, @sid, nonce,
                 data[(start_block + i) * block_size, block_size]
    end
    { :data => data, :hmacs => hmacs }
  end
  
  # Write operation.
  #
  # Args:
  #   start_block:: the first block in the read-write operation (0-based)
  #   block_count:: the number of blocks in the read_write operation
  #   data:: the data to be written; should be a String of exactly block_count *
  #          block_size bytes
  #   nonce:: short random string that prevents replay attacks
  #
  # Returns a Hash with the following keys:
  #   :hmacs:: an array of HMACs, one per block, confirming the write
  #
  # Raises an exception if something goes wrong.
  def write_blocks(start_block, block_count, nonce, data)
    # TODO(costan): Merkle tree stuff
    
    hmacs = (0...block_count).map do |i|
      @fpga.update start_block + i, @sid, nonce,
                   data[(start_block + i) * block_size, block_size]      
    end
    @disk.write_blocks start_block, block_count, data
    { :hmacs => hmacs }
  end
end  # class Scratchpad::Models::Server::Session

end  # namespace Scratchpad::Models::Server

end  # namespace Scratchpad::Models

end  # namespace Scratchpad
