require 'rubygems'
require 'test/unit'
require 'fakefs/safe'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'scratchpad'

class Test::Unit::TestCase
end

class IntegrationTestBase < Test::Unit::TestCase
  include Scratchpad::Models
  
  def setup
    @disk = Disk.empty_disk(1024 * 64, :block_count => 128).format
    @hash_tree = @disk.read_hash_tree

    @manufacturer = Manufacturer.dev_instance
    pair = @manufacturer.device_pair 512, @hash_tree.root_hash,
                                     @hash_tree.leaf_count
    @disk.write_manufacturing_state pair[:state]
    
    @fpga = Fpga.new pair[:fpga].attributes
    @smartcard = Smartcard.new pair[:card].attributes
    
    Manufacturer.boot_pair @fpga, pair[:card], @disk
    
    @server = Server.new @fpga, @disk
    @client = new_client    
  end
  
  def new_client
    Client.new @server, @manufacturer.root_certificate    
  end

  # :nodoc: ignore classes without tests
  def default_test    
  end
end
