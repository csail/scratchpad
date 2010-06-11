require 'socket'


# :nodoc: namespace
module Scratchpad

# Generic Ethernet functionality.
module Ethernet
  # A raw socket will receive all Ethernet frames, and send raw frames.
  def self.socket(if_name = nil, ether_type = nil)
    ether_type ||= all_ethernet_protocols
    socket = Socket.new raw_address_family, Socket::SOCK_RAW, htons(ether_type)
    socket.setsockopt Socket::SOL_SOCKET, Socket::SO_BROADCAST, true
    set_socket_interface(socket, if_name, ether_type) if if_name
    socket
  end
  
  # Sets the Ethernet interface and protocol type for a socket.
  def self.set_socket_interface(socket, if_name, ether_type)
    case RUBY_PLATFORM
    when /linux/
      if_number = get_interface_number if_name
      # struct sockaddr_ll in /usr/include/linux/if_packet.h
      socket_address = [raw_address_family, htons(ether_type), if_number,
                        0xFFFF, 0, 0, ""].pack 'SSISCCa8'
      socket.bind socket_address
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end
    socket
  end
    
  # The interface number for an Ethernet interface.
  def self.get_interface_number(if_name)
    case RUBY_PLATFORM
    when /linux/
      # /usr/include/net/if.h, structure ifreq
      ifreq = [if_name].pack 'a32'
      # 0x8933 is SIOCGIFINDEX in /usr/include/bits/ioctls.h
      socket.ioctl 0x8933, ifreq
      ifreq[16, 4].unpack('I').first
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end
  end
  
  # The MAC address for an Ethernet interface.
  def self.get_interface_mac(if_name)
    case RUBY_PLATFORM
    when /linux/
      # /usr/include/net/if.h, structure ifreq
      ifreq = [if_name].pack 'a32'
      # 0x8927 is SIOCGIFHWADDR in /usr/include/bits/ioctls.h
      socket.ioctl 0x8927, ifreq
      ifreq[18, 6].unpack('H*').first
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end    
  end
  
  # The protocol number for listening to all ethernet protocols.
  def self.all_ethernet_protocols
    case RUBY_PLATFORM
    when /linux/
      3
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end
  end
  
  # The AF / PF number for raw sockets.
  def self.raw_address_family
    case RUBY_PLATFORM
    when /linux/
      17  # cat /usr/include/bits/socket.h | grep PF_PACKET
    when /darwin/
      18  # cat /usr/include/sys/socket.h | grep AF_LINK
    else
      raise "Unsupported platform #{RUBY_PLATFORM}"
    end
  end

  # Converts a 16-bit integer from host-order to network-order.
  #
  # This is used internally by the rest of the code.
  def self.htons(short_integer)
    [short_integer].pack('n').unpack('S').first
  end
end  # namespace Scratchpad::Ethernet

end  # namespace Scratchpad
