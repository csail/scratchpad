require 'json'
require 'socket'

# :nodoc: namespace
module Scratchpad

# :nodoc: namespace
module Protocols


# Proxies a Server interface over a TCP socket.
class Server
  def initialize(server, port, host = '0.0.0.0')
    @done = false
    @server = server
    @socket = Socket.new Socket::AF_INET, Socket::SOCK_STREAM, 0
    sockaddr = Socket.pack_sockaddr_in port, host
    @socket.bind sockaddr
    @socket.listen 5
  end
  
  def process_client
    client_socket, client_addr = nil
    begin
      client_socket, client_addr = @socket.accept
    rescue IOError
      return if @done
      raise
    end
    session = Session.new client_socket, @server
    session.run
    client_socket.close
  end
  
  def run
    loop { process_client }
  end
  
  def close
    @done = true
    @socket.close
  end
end  # class Scratchpad::Protocols::Server

# :nodoc: namespace
class Server
  

# Proxies a Server session over a TCP socket.
class Session
  def initialize(socket, server)
    @socket = socket
    @server = server
  end

  def run
    done = false
    until done
      command = read_command
      result = case command['cmd']
      when 'endorsement_certificate'
        @server.endorsement_certificate
      when 'handshake'
        session_data = @server.session command['nonce'], command['key']
        @session = session_data[:session]
        session_data[:nonce_hmac]
      when 'block_count'
        @session.block_count
      when 'block_size'
        @session.block_size
      when 'close'
        if @session
          @session.close
          @session = nil
        end
        done = true
        'closed'
      when 'read'
        read_data = @session.read_blocks command['start'], command['count'],
                                         command['nonce']
        { 'data' => read_data[:data], 'hmacs' => read_data[:hmacs] }
      when 'write'
        @session.write_blocks(command['nonce'], command['start'],
                              command['count'], command['data'])[:hmacs]
      end
      write_response 'status' => 'ok', 'result' => result 
    end
  end
  
  def read_command
    packet = @socket.gets
    JSON.parse packet
  end
  private :read_command
  
  def write_response(response)
    packet = JSON.dump response
    packet += "\n"
    @socket.write packet
  end
  private :write_response
end  # class Scratchpad::Protocols::Server::Session
  
end  # namespace Scratchpad::Protocols::Server

end  # namespace Scratchpad::Protocols

end  # namespace Scratchpad
