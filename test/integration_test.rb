require File.expand_path('../helper.rb', __FILE__)

class IntegrationTest < Test::Unit::TestCase
  include Scratchpad::Models
  
  def setup
    @disk = Disk.new(1024 * 64, :block_count => 64).format
    @hash_tree = @disk.read_hash_tree

    @manufacturer = Manufacturer.dev_instance
    pair = @manufacturer.device_pair 512, @hash_tree.root_hash,
                                     @hash_tree.leaf_count
    @disk.write_manufacturing_state pair[:state]
    
    @fpga = Fpga.new pair[:fpga].attributes
    @smartcard = Smartcard.new pair[:card].attributes
    
    Manufacturer.boot_pair @fpga, pair[:card], @disk
    
    @server = Server.new @fpga, @disk
    @client = Client.new @server, @manufacturer.root_certificate
  end
  
  def test_read_write_one_block
    block = "\0" * @disk.block_size
    
    @client.write_blocks 1, 1, block
    assert_equal block, @client.read_blocks(1, 1), "Incorrect read"
  end
end
