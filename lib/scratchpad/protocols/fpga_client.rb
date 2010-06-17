require 'json'
require 'socket'

# :nodoc: namespace
module Scratchpad

# :nodoc: namespace
module Protocols

# Proxies a Server interface over a TCP socket.
class FpgaClient
  def initialize(fpga, if_name)
    @fpga = fpga    
    @counter = 1
    if if_name == 'sw'
      @ping = nil
    else
      @ping = Scratchpad::Ethernet::PingClient.new if_name, 0x88B5,
                                                   "001122334455"
    end
  end
  
  def capacity
    @fpga.capacity
  end
  
  def establish_session(session_id, nonce, encrypted_session_key)
    ping_fpga
    @fpga.establish_session session_id, nonce, encrypted_session_key
  end
  
  def close_session(session_id)
    ping_fpga
    @fpga.close_session session_id
    self
  end
  
  def perform_ops(ops)
    ping_fpga
    @fpga.perform_ops ops
  end
  
  def ping_fpga
    @counter += 1
    @ping.ping [@counter].pack('N').reverse if @ping
  end
  private :ping_fpga
end  # class Scratchpad::Protocols::FpgaClient

end  # namespace Scratchpad::Protocols

end  # namespace Scratchpad
