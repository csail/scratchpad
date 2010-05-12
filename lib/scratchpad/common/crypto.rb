 require 'openssl'

# :nodoc: namespace
module Scratchpad


# Cryptographic operations.
module Crypto
  # Creates an HMAC key.
  def self.hmac_key
    OpenSSL::Random.random_bytes ossl_crypto_hash.digest_length
  end
    
  # Creates a random string.
  def self.nonce
    OpenSSL::Random.random_bytes 16
  end
    
  # Creates an asymmetric key.
  #
  # Args:
  #   serialized:: (optional) a serialized key to de-serialize
  #
  # Returns a Hash with the following keys:
  #   :public:: the public key
  #   :private:: the private key
  def self.asymmetric_key(serialized = nil)
    k = OpenSSL::PKey::RSA.new(serialized || 1024)
    { :public => (k.public? ? k.public_key : nil),
      :private => (k.private? ? k : nil) }
  end

  # Serializes asymmetric keys to a string.
  #
  # Args:
  #   keys:: a Hash with the following keys:
  #          public:: the public key to serialize
  #          private:: the private key corresponding to the public key; can be
  #                    nil if only the private key should be serialized
  def self.save_asymmetric_keys(keys)
    (keys[:private] ? keys[:private] : keys[:public]).to_der
  end
  
  # Computes the HMAC for a bunch of data and a key.
  def self.hmac(key, data)
    OpenSSL::HMAC.digest ossl_crypto_hash, key, data
  end

  # Computes a cryptographic hash of the given data.
  def self.crypto_hash(data)
    ossl_crypto_hash.digest data
  end
  
  # Creates a CA (self-signed) certificate.
  #
  # Args:
  #   keys:: a Hash with the following keys:
  #          public:: the CA's public key
  #          private:: the CA's private key
  #   validity:: the certificate's validity, starting from now, in days
  #   distinguished_name:: the DN on the certificate, as a Hash (e.g.,
  #                        {'CN' => 'TEM CA', 'C' => 'US'}
  #
  # Returns a CA certificate.
  def self.ca_cert(keys, validity, distinguished_name)
    now = Time.now
    cert = OpenSSL::X509::Certificate.new
    dn = OpenSSL::X509::Name.new(distinguished_name.to_a)
    cert.subject = cert.issuer = dn
    cert.not_before = now;
    cert.not_after = now + validity * 60 * 60 * 24;
    cert.public_key = keys[:public]
    cert.serial = 0
    cert.version = 2
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = ef.issuer_certificate = cert
    cert.extensions = [
      ef.create_extension("basicConstraints", "CA:TRUE", true),
      ef.create_extension("keyUsage", "cRLSign,keyCertSign", true),
      ef.create_extension("nsCertType", "emailCA,sslCA"),
      ef.create_extension("subjectKeyIdentifier", "hash")
    ]
    cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                           "keyid:always,issuer:always")
    cert.sign keys[:private], OpenSSL::Digest::SHA1.new
    
    cert
  end
  
  # Serializes a certificate to a string.
  #
  # Args:
  #   cert:: the certificate to be serialized
  #
  # Returns a string.
  def self.save_cert(cert)
    cert.to_der
  end
  
  # De-serializes a certificate from a string.
  #
  # Args:
  #   serialized:: the string that the certificate was serialized to
  #
  # Returns the de-serialized certificate.
  def self.load_cert(serialized)
    OpenSSL::X509::Certificate.new serialized
  end

  # The OpenSSL cryptographic hashing engine.
  def self.ossl_crypto_hash
    OpenSSL::Digest::Digest.new 'sha1'
  end
end  # module Scratchpad::Crypto

end  # namespace Scratchpad
