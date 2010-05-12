# :nodoc: namespace
module Scratchpad

# :nodoc: namespace
module Models


# Model for the high-performance trusted storage client.
class Client
  # Creates a new client session to the given server.
  def initialize(server, options = {})    
    server_ecert = server.endorsement_certificate
    # TODO(costan): verify endorsement certificate
      
    server_pubek = server_ecert.public_key
    nonce = Crypto.nonce
    @session_key = Crypto.hmac_key
    response = server.session Crypto.pki_encrypt(server_pubek, @session_key)
    unless response[:nonce_hmac] == Crypto.hmac(session_key, nonce)
      raise "Invalid session acknowledgement"
    end
    @session = response[:session]
    
    @block_size = server.block_size
    @block_count = server.block_count    
  end
    
  # The size of a storage block. Operations are atomic at the block level.
  def block_size
    @block_size
  end

  # The number of blocks available on this server.
  def block_count
    @block_count
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
    nonce = Crypto.nonce
    response = @session.read_blocks start_block, block_count, nonce
    validate_hmacs nonce, start_block, block_count, response[:data],
                   response[:hmacs]
    response[:data]
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
    nonce = Crpyto.nonce
    response = @session.write_blocks nonce, start_block, block_count, data
    validate_hmacs nonce, start_block, block_count, data, response[:hmacs]
  end
    
  # Validates the FPGA-issued HMACs for a read/write operation.
  def validate_hmacs(nonce, start_block, block_count, data, hmacs)
    0.upto(block_count - 1) do |i|
      hmac_data = [Crypto.crypto_hash(data[i * block_size]),
                   [start_block + i].pack('N'), nonce].join
      unless hmacs[i] == Crypto.hmac(@session_key, hmac_data)
        raise "Data authentication error"
      end
    end
  end
end  # class Scratchpad::Models::Client

end  # namespace Scratchpad::Models

end  # namespace Scratchpad
