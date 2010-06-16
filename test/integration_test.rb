require File.expand_path('../helper.rb', __FILE__)

class IntegrationTest < IntegrationTestBase  
  def test_read_write_one_block
    block = "\0" * @disk.block_size
    
    @client.write_blocks 1, 1, block
    assert_equal block, @client.read_blocks(1, 1), "Incorrect read"
  end
end
