require File.expand_path('../helper.rb', __FILE__)

class ServerProtocolTest < IntegrationTestBase
  def setup
    super

    Thread.abort_on_exception = true

    port = 18990 + rand(100)
    @server_server = Scratchpad::Protocols::Server.new @server, port
    Thread.new { @server_server.run }
    @server = Scratchpad::Protocols::ServerClient.new port
    @client = new_client
    
  end
  
  def teardown
    super
    @server_server.close
  end
  
  def test_read_write_one_block
    block = "\0" * @disk.block_size
    
    @client.write_blocks 1, 1, block
    assert_equal block, @client.read_blocks(1, 1), "Incorrect read"
  end
end
