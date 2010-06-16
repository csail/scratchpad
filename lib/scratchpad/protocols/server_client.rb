require 'json'
require 'socket'

# :nodoc: namespace
module Scratchpad

# :nodoc: namespace
module Protocols

# Proxies a Server interface over a TCP socket.
class ServerClient
  def initialize(port, host = '127.0.0.1')
    @port = port
    @host = host
  end
  
  def endorsement_certificate
    new_session = socket_session
    certificate = new_session.endorsement_certificate
    new_session.close
    certificate
  end
  
  def socket_session
    socket = Socket.new Socket::AF_INET, Socket::SOCK_STREAM, 0
    sockaddr = Socket.pack_sockaddr_in @port, @host
    socket.connect sockaddr
    Session.new(socket)    
  end
  private :socket_session
  
  def session(nonce, encrypted_session_key)
    new_session = socket_session
    nonce_hmac = new_session.handshake nonce, encrypted_session_key
    { :session => new_session, :nonce_hmac => nonce_hmac }
  end
end  # class Scratchpad::Protocols::ServerClient

# :nodoc: namespace
class ServerClient


# Proxies a Server session interface over a TCP socket.
class Session
  def initialize(socket)
    @socket = socket
  end
  
  def endorsement_certificate
    Crypto.load_cert rt('cmd' => 'endorsement_certificate')
  end
  
  def handshake(nonce, encrypted_session_key)
    rt 'cmd' => 'handshake', 'nonce' => nonce, 'key' => encrypted_session_key 
  end
    
  def block_count
    rt 'cmd' => 'block_count'
  end
  
  def block_size
    rt 'cmd' => 'block_size'
  end
  
  def close
    rt 'cmd' => 'close'
    @socket.close
  end

  def read_blocks(start_block, block_count, nonce)
    read_data = rt 'cmd' => 'read', 'start' => start_block,
                   'count' => block_count, 'nonce' => nonce
    { :data => read_data['data'], :hmacs => read_data['hmacs'] }
  end

  def write_blocks(nonce, start_block, block_count, data)
    hmacs = rt 'cmd' => 'write', 'start' => start_block, 'count' => block_count,
               'nonce' => nonce, 'data' => data
    { :hmacs => hmacs }
  end
    
  def rt(command)
    packet = JSON.dump command
    packet += "\n"
    @socket.write packet
    response = JSON.parse(@socket.gets)
    raise "Server error: #{response.inspect}" unless response['status'] == 'ok'
    response['result']
  end
  private :rt
end  # class Scratchpad::Protocols::ServerClient::Session

end  # namespace Scratchpad::Protocols::ServerClient

end  # namespace Scratchpad::Protocols

end  # namespace Scratchpad
