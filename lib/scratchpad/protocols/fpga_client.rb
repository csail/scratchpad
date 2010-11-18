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
  
  # Computes 4 block digests in parallel.
  def do_digests(blocks)
    raise 'Need exactly 4 blocks' unless blocks.length == 4
    
    chunk_length = 512 / 8  # 512 bits for SHA-1 chunk
    packet_chunk_count = 5
    packet_chunks = (0...packet_chunk_count).to_a
    segment_length = chunk_length * packet_chunk_count
    unless blocks.first.length % segment_length == 0
      raise "Block length needs to be a multiple of #{segment_length}"
    end
    
    send_header = [@ping.dest_mac, @ping.source_mac, [0x88B5].pack('n')].join
    recv_header = [@ping.source_mac, @ping.dest_mac, [0x88B5].pack('n')].join
    
    last_packet_id = blocks.first.length / segment_length - 1
    0.upto last_packet_id do |packet_id|
      command_byte = case packet_id
      when 0
        0xAA
      when last_packet_id
        0xCC
      else
        0xBB
      end
      packet = [send_header, command_byte.chr, packet_chunks.map { |chunk|
        blocks.map { |block|
          block[(packet_id * packet_chunk_count + chunk) * chunk_length,
                chunk_length]
        }
      }].flatten.join
      @ping.socket.send packet, 0
    end
    
    loop do
      packet = @ping.socket.recv 1600
      next unless packet[0, recv_header.length] == recv_header.length
      
      digests = []
      blocks.each_index do |i|
        digests << packet[recv_header.length + digest_length * i, digest_length]
      end
      return digests
    end
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
