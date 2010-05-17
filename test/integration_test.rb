require 'helper.rb'

class IntegrationTest < Test::Unit::TestCase
  include Scratchpad::Models
  
  def setup
    @manufacturer = Manufacturer.dev_instance
    pair = @manufacturer.device_pair
    @fpga = pair[:fpga]
    @fpga.boot
    @disk = Disk.new 1024 * 64, :block_count => 64
    
    @server = Server.new @fpga, @disk
    @client = Client.new @server, @manufacturer.root_certificate
  end
  
  def test_read_write_one_block
    block = "\0" * @disk.block_size
    
    @client.write_blocks 1, 1, block
    assert_equal block, @client.read_blocks(1, 1), "Incorrect read"
  end
end
