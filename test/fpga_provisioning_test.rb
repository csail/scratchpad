require File.expand_path('../helper.rb', __FILE__)

class FpgaProvisioningTest < Test::Unit::TestCase
  Provision = Scratchpad::Fpga::Provision
  def test_xilinx_bin_path
    assert File.exist?(File.join(Provision.xilinx_bin_path, 'impact')),
           'Failed to find impact in xilinx binpath'
  end
end
