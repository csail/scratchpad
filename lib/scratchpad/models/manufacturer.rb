require 'yaml'

# :nodoc: namespace
module Scratchpad

# :nodoc: namespace
module Models


# Model for the trusted equipment manufacturer.
class Manufacturer
  # Instantiates a new manufacturer.
  def initialize(attributes = {})
    if attributes[:key]
      @ca_keys = Crypto.asymmetric_key attributes[:key]
    else
      @ca_keys = Crypto.asymmetric_key
    end
    
    if attributes[:cert]
      @ca_cert = Crypto.load_cert attributes[:cert]
    else
      # TODO(costan): customize the CA 
      proto_cert = Crypto.ca_cert @ca_keys, 365, self.class.distinguished_name
      @ca_cert = Crypto.load_cert Crypto.save_cert(proto_cert)
    end
  end
    
  # The data that needs to be persisted to re-create the manufacturer.
  #
  # Returns a Hash whose keys are symbols and values are strings.
  def attributes
    { :key => Crypto.save_asymmetric_keys(@ca_keys),
      :cert => Crypto.save_cert(@ca_cert) }
  end
  
  # The manufacturer instance associated with development chips.
  def self.dev_instance
    devkeys_dir = File.expand_path '../../dev_keys', __FILE__
    devkeys_cf = File.join devkeys_dir, 'manufacturer.crt'
    devkeys_kf = File.join devkeys_dir, 'manufacturer.key.der'
    devkeys_yml = File.join devkeys_dir, 'manufacturer.yml'

    unless File.exist?(devkeys_yml)
      attributes = Manufacturer.new.attributes
      File.open(devkeys_kf, 'wb') { |f| f.write attributes[:key] }
      File.open(devkeys_cf, 'wb') { |f| f.write attributes[:cert] }
      File.open(devkeys_yml, 'w') { |f| f.write YAML.dump attributes, f }
    end
    
    attributes = File.open(devkeys_yml, 'r') { |f| YAML.load f }
    Manufacturer.new attributes
  end
  
  # The DN in the manufacturer CA.
  def self.distinguished_name
    {
      'CN' => 'Trusted Execution Module Development CA',
      'OU' => 'Computer Science and Artificial Intelligence Laboratory',
      'O' => 'Massachusetts Insitute of Technology',
      'L' => 'Cambridge', 'ST' => 'Massachusetts', 'C' => 'US'
    }
  end
  
  # Manufactures a new FPGA and smart-card, which are paired.
  #
  # Returns: a Hash with the following keys:
  #   :fpga:: the new FPGA
  #   :card:: the new smart-card
  def device_pair
    endorsement_key = Crypto.asymmetric_keys
    endorsement_cert = Crypto.cert(device_distinguished_name,
                                   endorsement_key[:public],
                                   @ca_cert, @ca_keys)
        
    fpga = Fpga.new
    card = Smartcard.new
    { :card => card, :fpga => fpga }
  end
  
  def device_distinguished_name
    {
      'CN' => 'Trusted Execution Module',
      'OU' => 'Computer Science and Artificial Intelligence Laboratory',
      'O' => 'Massachusetts Insitute of Technology',
      'L' => 'Cambridge', 'ST' => 'Massachusetts', 'C' => 'US'
    }
  end
end  # class Scratchpad::Models::Manufacturer

end  # namespace Scratchpad::Models

end  # namespace Scratchpad
