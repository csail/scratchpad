require 'openssl'

module Scratchpad


# Cryptographic operations.
module Crypto
  # Creates a symmetric key.
  def symmetric_key
    symmetric_cipher.random_key
  end
  
  # Creates an HMAC key.
  def hmac_key
    OpenSSL::Random.random_bytes crpyto_hash.digest_length
  end
  
  # Computes the HMAC for a bunch of data and a key.
  def hmac(key, data)
    OpenSSL::HMAC.digest(crpyto_hash, key, data)    
  end
  
  # Creates a random string.
  def nonce
    OpenSSL::Random.random_bytes 16
  end
  
  # Creates an asymmetric key.
  #
  # Returns a Hash with the following keys:
  #   :public:: the public key
  #   :private:: the private key
  def asymmetric_key
    k = OpenSSL::PKey::RSA.new 1024
    { :public => k.public_key, :private => k }
  end
  
  # TODO(costan): certificate stuff

  # The symmetric encryption cipher.
  def symmetric_cipher
    OpenSSL::Cipher::Cipher.new 'aes-128-cbc'
  end
  private :symmetric_cipher
  
  # The cryptographic hash function.
  def crypto_hash
    OpenSSL::Digest::Digest.new 'sha1'
  end
  private :crypto_hash
end  # module Scratchpad::Crypto

end  # namespace Scratchpad
