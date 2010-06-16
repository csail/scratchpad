# :nodoc: namespace
module Scratchpad

# :nodoc: namespace
module Models


# Model for the trusted FPGA.
class Fpga
  # Instantiates a new FPGA model.
  def initialize(attributes = {})
    @ca_cert = Crypto.load_cert attributes[:ca_cert]
    @cache_capacity = attributes[:capacity]
    
    if attributes[:puf]
      # Restoring an existing FPGA's state.
      @puf = attributes[:puf]
      @efuses = attributes[:fuses]
    else
      # Manufacturing a new FPGA.
      @puf = nil
      @efuses = nil
    end
    
    @nonce = Crypto.nonce
    @syndrome = nil
    @fpga_key = nil
    @booted = false
  end
  
  def attributes
    {
      :ca_cert => Crypto.save_cert(@ca_cert),
      :capacity => @cache_capacity,
      :puf => @puf, :fuses => @efuses,      
    }
  end
  
  # The size of the FPGA's node cache.
  def capacity
    @cache_capacity
  end
    
  # Generates the FPGA nonce, used to boot the smart-card.
  #
  # Args:
  #   puf_syndrome:: the information needed to recover the FPGA's symmetric key
  #                  out of its PUF
  #
  # Returns a hash with the following keys:
  #   :nonce:: a randomly generated nonce
  #   :hmac:: the nonce's HMAC, keyed under the FPGA's symmetric key
  def preboot(puf_syndrome)
    raise "Already booted" if @booted
    
    raise "Syndrome already installed" if @syndrome
    unless @efuses == Crypto.crypto_hash(puf_syndrome)
      raise "Incorrect PUF syndrome"
    end
    @syndrome = puf_syndrome
    recover_key

    { :nonce => @nonce, :hmac => Crypto.hmac(@fpga_key, @nonce) }
  end
  
  # Information needed to generate the FPGA's symmetric key out of its PUF.
  def puf_syndrome
    raise "Not yet initialized" unless @syndrome
    @syndrome
  end
  
  # Boots up the FPGA.
  #
  # Args:
  #   root_hash:: the storage root key
  #   leaf_count:: number of leaves in the storage tree
  #   root_hmac:: HMAC over the FPGA's nonce, root hash, and leaf count, keyed
  #               with the FPGA's symmetric key
  #   endorsement_key:: the private endorsement key for the FPGA / smart-card
  #                     pair, encrypted with the FPGA's symmetric key
  #
  # Returns self.
  #
  # Raises:
  #   RuntimeError:: if the FPGA has already booted
  #   RuntimeError:: if the PUF syndrome doesn't match the cryptographic hash
  #                  stored in the FPGA's e-fuses
  #   RuntimeError:: if the HMAC doesn't match the boot parameters
  def boot(root_hash, leaf_count, root_hmac, endorsement_key)
    raise "Already booted" if @booted
    
    unless root_hmac == Fpga.root_hash_hmac(@fpga_key, @nonce, root_hash,
                                                               leaf_count)
      raise "Incorrect HMAC"
    end
    @endorsement_key =
        Crypto.key_pair Crypto.sk_decrypt(@fpga_key, endorsement_key)
    @cache = Scratchpad::HashTreeCache.new @cache_capacity, root_hash,
                                           leaf_count
    @booted = true
    @nonce = nil
    
    @session_keys = []
    self
  end
  
  # The HMAC needed to validate a storage root hash.
  #
  # Args:
  #   fpga_key:: the FPGA's symmetric encryption key
  #   fpga_nonce:: the nonce generated by the FPGA at pre-boot time
  #   root_hash:: the storage root hash to be validated
  #   leaf_count:: the number of leaves in the storage tree
  def self.root_hash_hmac(fpga_key, fpga_nonce, root_hash, leaf_count)
    Crypto.hmac fpga_key, [fpga_nonce, [leaf_count].pack('N'), root_hash].join
  end  

  # The FPGA's symmetric key, encrypted under a smart card's endorsement key.
  #
  # Args:
  #   endorsement_cert:: the smartcard's endorsement certificate, issued by the
  #                      manufacturer
  #
  # Returns the FPGA's symmetric key, encrypted under the public key in the
  # endorsement certificate.
  #
  # Raises:
  #   RuntimeError:: the FPGA is already paired with a smart-card
  #   RuntimeError:: the endorsement certificate doesn't match the
  #                  manufacturer's CA key
  def encrypted_key(endorsement_cert)
    raise "Already paired" if @efuses
    
    unless Crypto.verify_cert endorsement_cert, [@ca_cert]
      raise "Invalid endorsement certificate"
    end
    
    generate_key
    Crypto.pki_encrypt endorsement_cert.public_key, @fpga_key
  end

  # Generates the FPGA's symmetric key.
  #
  # This happens when the FPGA is powered up for the first time, in the
  # manufacturer's facility, before being paired up with a smart-card.
  def generate_key
    @fpga_key = Crypto.sk_key
    @puf = @fpga_key[0...-1]
    @syndrome = Crypto.sk_encrypt(@fpga_key, (0..32).to_a.pack('C*'))
    @efuses = Crypto.crypto_hash @syndrome
  end
  private :generate_key
  
  # Recovers the FPGA's symmetric key from the syndrome and PUF.
  def recover_key
    0.upto(255).each do |ch|
      @fpga_key = [@puf, [ch].pack('C')].join
      if @syndrome == Crypto.sk_encrypt(@fpga_key, (0..32).to_a.pack('C*'))
        break 
      end
    end
  end
  private :recover_key
end  # class Scratchpad::Models::Fpga

# :nodoc: FPGA operation
class Fpga
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
    session_key = Crypto.pki_decrypt @endorsement_key[:private],
                                     encrypted_session_key
    @session_keys[session_id] = session_key
    Crypto.hmac session_key, nonce
  end
  
  # Tears down a session between a trusted-storage client and the FPGA.
  #
  # Returns self.
  def close_session(session_id)
    @session_keys.delete session_id
    self
  end
  
  # The main communication method with the storage server.
  #
  # The ops argument is a buffer of operations. Each operation is executed
  # sequentially (for now). The operation type is indicated by the value for the
  # :op key.
  def perform_ops(ops)
    response = []
    ops.each do |op|
      case op[:op]
      when :load
        @cache.load_entry op[:line], op[:node], op[:node_hash],
                          op[:old_parent_line]        
      when :verify
        @cache.verify_children op[:parent], op[:left], op[:right]
      when :sign
        response << hmac(op[:block], op[:session_id], op[:nonce], op[:line],
                         op[:data])
      when :update
        response << update(op[:block], op[:session_id], op[:nonce], op[:path],
                           op[:data])
      else
        raise "Invalid operation type #{op[:op]}"
      end
    end
    response
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
  def hmac(block_number, session_id, nonce, cache_entry, data)
    @cache.check_hash cache_entry, @cache.leaf_node_id(block_number),
                      Crypto.crypto_hash(data)
    hmac_without_check! block_number, session_id, nonce, data    
  end
  private :hmac
  
  # Certifies an update to a block's contents.
  #
  # Args:
  #   block_number:: the block number (0-based)
  #   session_id:: the slot containing the client session key
  #   nonce:: short random string that prevents replay attacks
  #   data:: the block's new contents
  #
  # Returns: HMAC(Digest(data) || block_number || nonce)
  def update(block_number, session_id, nonce, update_path, data)
    data_hash = Crypto.crypto_hash(data)
    @cache.update_leaf_value update_path, data_hash
    @cache.check_hash update_path.first, @cache.leaf_node_id(block_number),
                      data_hash
    hmac_without_check! block_number, session_id, nonce, data        
  end
  private :update
  
  # Certifies a block's contents without performing any verification.
  #
  # Args:
  #   block_number:: the block number (0-based)
  #   session_id:: the slot containing the client session key
  #   nonce:: short random string that prevents replay attacks
  #   data:: the block's contents
  #
  # Returns: HMAC(Digest(data) || block_number || nonce)
  def hmac_without_check!(block_number, session_id, nonce, data)
    session_key = @session_keys[session_id]
    Crypto.hmac_for_block block_number, data, nonce, session_key
  end
  private :hmac_without_check!
end  # class Scratchpad::Models::Fpga

end  # namespace Scratchpad::Models

end  # namespace Scratchpad
