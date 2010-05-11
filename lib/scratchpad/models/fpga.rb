# :nodoc: namespace
module Scratchpad

# :nodoc: namespace
module Models


# Model for the trusted FPGA.
class Fpga
  def initialize
  end
  
  # An OpenSSL endorsement certificate for the FPGA.
  def endorsement_certificate
    
  end

  # Establishes a session between a trusted-storage client and the FPGA.
  #
  # Args:
  #   session_id:: a low number specifying the key slot used by this session
  #   encrypted_session_key:: the client-generated symmetric session key,
  #                           encrypted under the FPGA's public
  #                           Endorsement Key
  def establish_session(session_id, encrypted_session_key)
    
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
    
  end
end  # class Scratchpad::Models::Fpga

end  # namespace Scratchpad::Models

end  # namespace Scratchpad
