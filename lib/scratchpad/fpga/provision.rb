# :nodoc: namespace
module Scratchpad
  
# :nodoc: namespace
module Fpga
  
# Methods for provisioning the FPGA.
module Provision
  # Path to Xilinx's binaries.
  def self.xilinx_bin_path
    @xilinx_path ||= xilinx_bin_path_without_cache
  end
  
  # Uncached (and slow!) version of xilinx_bin_path.
  def self.xilinx_bin_path_without_cache
    paths = Dir.glob('/opt/**/impact')
    paths = Dir.glob('/usr/**/impact') if paths.empty?
    
    if RUBY_PLATFORM.index('64')
      paths = paths.select { |path| path.index '64' }
    else
      paths = paths.reject { |path| path.index '64' }
    end    
    
    File.dirname paths.sort.last
  end
end  # module Scratchpad::Fpga::Provision
  
end  # namespace Scratchpad::Fpga

end  # namespace Scratchpad