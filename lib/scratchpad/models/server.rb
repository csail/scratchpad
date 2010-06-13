# :nodoc: namespace
module Scratchpad

# :nodoc: namespace
module Models


# Model for the high-performance trusted storage server.
class Server
  # Instantiates a server model.
  #
  # Args:
  #   fpga:: a trusted FPGA attached to this server
  #   disk:: an untrusted disk providing the server's storage
  def initialize(fpga, disk, options = {})    
    @fpga = fpga
    @disk = disk    
    @ecert = disk.manufacturing_state[:endorsement_cert]
    @data_start = disk.header_blocks
    @tree = disk.read_hash_tree
    @tree_driver = HashTreeCacheDriver.new @tree, fpga.capacity
  end
  
  # Endorsement Certificate for the FPGA on the server.
  def endorsement_certificate
    @ecert
  end
  
  # Creates a session with a client.
  #
  # Args:
  #   nonce:: short random string that prevents replay attacks
  #   encrypted_session_key:: the client-generated symmetric session key,
  #                           encrypted under the server's public
  #                           Endorsement Key
  #
  # Returns a Hash with the following keys:
  #   :nonce_hmac:: proof from the FPGA that the session was acknowledged
  #   :session:: a Server::Session object
  def session(nonce, encrypted_session_key)
    sid = 0  # TODO(costan): FPGA session allocation
    nonce_hmac = @fpga.establish_session sid, nonce, encrypted_session_key
    server_session = Session.new @fpga, @disk, sid, @data_start,
                                 @tree, @tree_driver
    { :nonce_hmac => nonce_hmac, :session => server_session }
  end
end  # class Scratchpad::Server

# :nodoc: namespace
class Server

# A session between a trusted-storage server and a client.
class Session  
  def initialize(fpga, disk, sid, data_start, tree, tree_driver, options = {})
    @fpga = fpga
    @disk = disk
    @data_start = data_start
    @sid = sid
    @tree = tree
    @tree_driver = tree_driver
  end

  # The number of blocks available on the disk.
  def block_count
    @disk.block_count - @data_start
  end
  
  # The size of a disk block. All transfers work on blocks.
  def block_size
    @disk.block_size
  end
  
  # Read operation.
  #
  # Args:
  #   start_block:: the first block in the read-write operation (0-based)
  #   block_count:: the number of blocks in the read_write operation
  #   nonce:: short random string that prevents replay attacks
  #
  # Returns a Hash with the following keys:
  #   :data:: the result of the read
  #   :hmacs:: an array of HMACs, one per block, for the read results
  #
  # Raises an exception if something goes wrong. 
  def read_blocks(start_block, block_count, nonce)
    data = @disk.read_blocks start_block + @data_start, block_count
    hmacs = (0...block_count).map do |i|
      load_data = @tree_driver.load_leaf start_block + i
      load_data[:ops] <<
          { :op => :sign, :line => load_data[:line], :session_id => @sid,
            :nonce => nonce, :data => data[i * block_size, block_size],
            :block => start_block + i }
      add_tree_data_to_ops load_data[:ops]
      response = @fpga.perform_ops load_data[:ops]
      response.first
    end
    { :data => data, :hmacs => hmacs }
  end
  
  # Write operation.
  #
  # Args:
  #   start_block:: the first block in the read-write operation (0-based)
  #   block_count:: the number of blocks in the read_write operation
  #   data:: the data to be written; should be a String of exactly block_count *
  #          block_size bytes
  #   nonce:: short random string that prevents replay attacks
  #
  # Returns a Hash with the following keys:
  #   :hmacs:: an array of HMACs, one per block, confirming the write
  #
  # Raises an exception if something goes wrong.
  def write_blocks(nonce, start_block, block_count, data)
    # TODO: transactional integrity
    
    hmacs = (0...block_count).map do |i|
      load_data = @tree_driver.load_update_path start_block + i
      load_data[:ops] <<
          { :op => :update, :path => load_data[:path], :nonce => nonce,
            :data => data[i * block_size, block_size],
            :block => start_block + i, :session_id => @sid }
      add_tree_data_to_ops load_data[:ops]
      response = @fpga.perform_ops load_data[:ops]
      response.first
    end
    @disk.write_blocks start_block + @data_start, block_count, data
    { :hmacs => hmacs }
  end
  
  # Fills in the node hash in cache operations.
  #
  # Takes in a buffer of operations, and returns the same buffer.
  def add_tree_data_to_ops(ops)
    ops.each do |op|
      op[:node_hash] = @tree[op[:node]] if op[:op] == :load
    end
    ops
  end
  private :add_tree_data_to_ops
end  # class Scratchpad::Models::Server::Session

end  # namespace Scratchpad::Models::Server

end  # namespace Scratchpad::Models

end  # namespace Scratchpad
