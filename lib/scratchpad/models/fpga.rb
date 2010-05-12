# :nodoc: namespace
module Scratchpad

# :nodoc: namespace
module Models


# Model for the trusted FPGA.
class Fpga
  def initialize(attributes = {})
    # TODO(costan): replace this with the proper initialization sequence
    @endorsement_certificate = attributes[:ecert]
    @endorsement_key = attributes[:ekey]
    
    @booted = false
  end
  
  
  def boot
    raise "Already booted!" if @booted
    @session_keys = []    
  end
  
  # An OpenSSL endorsement certificate for the FPGA.
  def endorsement_certificate
    @endorsement_certificate
  end

  # Establishes a session between a trusted-storage client and the FPGA.
  #
  # Args:
  #   session_id:: a low number specifying the key slot used by this session
  #   nonce:: short random string that prevents replay attacks
  #   encrypted_session_key:: the client-generated symmetric session key,
  #                           encrypted under the FPGA's public
  #                           Endorsement Key
  #
  # Returns the HMAC of the given nonce under the session key.
  def establish_session(session_id, nonce, encrypted_session_key)
    session_key = @endorsement_key.decrypt encrypted_session_key
    @session_keys[session_id] = session_key
    Crypto.hmac session_key, nonce
  end
  
  # Certifies a block's contents.
  #
  # Args:
  #   block_number:: the block number (0-based)
  #   session_id:: the slot containing the client session key
  #   nonce:: short random string that prevents replay attacks
  #   data:: the block's contents
  #
  # Returns: HMAC(Digest(data) || block_number || nonce)
  def hmac(block_number, session_id, nonce, data)
    # TODO(costan): the actual check
    hmac_without_check! block_number, session_id, nonce, data    
  end
  
  # Certifies an update to a block's contents.
  #
  # Args:
  #   block_number:: the block number (0-based)
  #   session_id:: the slot containing the client session key
  #   nonce:: short random string that prevents replay attacks
  #   data:: the block's new contents
  #
  # Returns: HMAC(Digest(data) || block_number || nonce)
  def update(block_number, session_id, nonce, data)
    # TODO(costan): the actual check
    hmac_without_check! block_number, session_id, nonce, data        
  end
  
  # Certifies a block's contents without performing any verification.
  #
  # Args:
  #   block_number:: the block number (0-based)
  #   session_id:: the slot containing the client session key
  #   nonce:: short random string that prevents replay attacks
  #   data:: the block's contents
  #
  # Returns: HMAC(Digest(data) || block_number || nonce)
  def hmac(block_number, session_id, nonce, data)
    session_key = @session_keys[session_id]
    hmac_data = [[block_number].pack('N'), nonce, Crypto.crypto_hash(data)]
    Crypto.hmac session_key, hmac_data
  end
end  # class Scratchpad::Models::Fpga

end  # namespace Scratchpad::Models

end  # namespace Scratchpad
