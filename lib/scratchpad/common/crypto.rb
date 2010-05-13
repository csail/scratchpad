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
  def self.key_pair(serialized = nil)
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
  def self.save_key_pair(keys)
    (keys[:private] ? keys[:private] : keys[:public]).to_der
  end
  
  # Encrypts a string with a public key.
  #
  # Args:
  #   public_key:: the public key to encrypt with
  #   data:: the string to encrypt
  #   
  # Returns a string 
  def self.pki_encrypt(public_key, data)
    public_key.public_encrypt data, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
  end

  # Decrypts a string with a private key.
  #
  # Args:
  #   public_key:: the public key to encrypt with
  #   data:: the string to encrypt
  #   
  # Returns a string 
  def self.pki_decrypt(private_key, encrypted_data)
    private_key.private_decrypt encrypted_data,
                                OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
  end

  # Computes the HMAC for a bunch of data and a key.
  def self.hmac(key, data)
    OpenSSL::HMAC.digest ossl_crypto_hash, key, data
  end

  # Computes a cryptographic hash of the given data.
  def self.crypto_hash(data)
    ossl_crypto_hash.digest data
  end
  
  # Produces a certificate.
  #
  # Args:
  #   distinguished_name:: the DN on the certificate, as a Hash (e.g.,
  #                        {'CN' => 'TEM CA', 'C' => 'US'}
  #   validity:: the certificate's validity, starting from now, in days
  #   ca_keys:: Hash with the following values:
  #             :public:: the public part of the CA signing key pair
  #             :private:: the private part of the CA signing key pair
  #   ca_cert:: the CA's certificate; use nil to produce a root CA
  #   public_key:: the key which is being certified; for a root CA, this should
  #                be nil, as the key pair in ca_keys will sign itself
  #
  # Returns a certificate.
  def self.cert(distinguished_name, validity, ca_keys,
                ca_cert = nil, public_key = nil)
    now = Time.now
    cert = OpenSSL::X509::Certificate.new
    dn = OpenSSL::X509::Name.new(distinguished_name.to_a)
    cert.subject = dn
    cert.issuer = ca_cert ? ca_cert.subject : dn
    cert.not_before = now;
    cert.not_after = now + validity * 60 * 60 * 24;
    cert.public_key = public_key || ca_keys[:public]
    cert.serial = 0
    cert.version = 2
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = ca_cert || cert
    cert.extensions = [
      ca_cert ? ef.create_extension("basicConstraints", "CA:TRUE", true) :
                ef.create_extension("basicConstraints", "CA:FALSE"),
      ca_cert ? ef.create_extension("keyUsage", "cRLSign,keyCertSign", true) :
                ef.create_extension("keyUsage", "digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyAgreement,keyCertSign,cRLSign", true),
      ca_cert ? ef.create_extension("nsCertType", "emailCA,sslCA") :
                ef.create_extension("nsCertType", "emailCA,sslCA,client,email,objsign,server"),
      ef.create_extension("subjectKeyIdentifier", "hash")
    ]
    cert.add_extension ef.create_extension("authorityKeyIdentifier",
                                           "keyid:always,issuer:always")
    cert.sign ca_keys[:private], OpenSSL::Digest::SHA1.new
    
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
  
  # Verifies a certificate using a set of trusted roots.
  #
  # Args:
  #   cert:: the certificate to be verified
  #   ca_certs:: certificates for CAs to be used as roots of trust
  def self.verify_cert(cert, ca_certs)
    store = OpenSSL::X509::Store.new
    ca_certs.each { |ca_cert| store.add_cert ca_cert }
    store.verify cert
  end

  # The OpenSSL cryptographic hashing engine.
  def self.ossl_crypto_hash
    OpenSSL::Digest::Digest.new 'sha1'
  end
end  # module Scratchpad::Crypto

end  # namespace Scratchpad
