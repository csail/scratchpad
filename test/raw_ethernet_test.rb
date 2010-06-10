require File.expand_path('../helper.rb', __FILE__)

class RawEthernetTest < Test::Unit::TestCase
  def test_mac
    if_name = 'eth0'
    golden_mac = `ifconfig #{if_name}`[/HWaddr .*$/][7..-1].gsub(':', '').strip
    mac = Scratchpad::Ethernet.get_interface_mac('eth0')
    assert_equal golden_mac, mac
  end
end
