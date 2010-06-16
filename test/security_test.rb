require File.expand_path('../helper.rb', __FILE__)

class IntegrationTest < IntegrationTestBase  
  def test_replay_attack
    forked_disk = Disk.new @disk.attributes
    
    block = "\1" * @disk.block_size
    
    @client.write_blocks 1, 1, block
    assert_equal block, @client.read_blocks(1, 1), "Incorrect read"

    @server.instance_variable_set :@disk, forked_disk
    @client = new_client
    assert_raise Scratchpad::HashTreeCache::Exceptions::IncorrectNodeHash,
                 "Replay attack setup failed" do
      assert_equal block, @client.read_blocks(1, 1),
                   "Incorrect read from forked disk (replay attack)"
    end
  end
end
