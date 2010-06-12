require 'fileutils'

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
  
  def self.usb_cable_driver_path
    File.join xilinx_bin_path, 'libusb-driver.so'
  end
  
  # Builds and installs the Xilinx USB cable driver.
  #
  # This is more complicated than it seems.
  def self.install_cable_driver
    # Clone and build the USB cable driver.
    packages = ['git-core', 'libusb-dev', 'build-essential', 'fxload']
    unless Kernel.system("apt-get install #{packages.join(' ')}")
      raise 'Failed to install packages.'
    end    
#    unless Kernel.system('git clone file:///home/victor/workspace/usb-driver')
    unless Kernel.system('git clone git://git.zerfleddert.de/usb-driver')
      raise 'Failed to git-clone the USB cable driver.'
    end
    Dir.chdir('usb-driver') do
      unless Kernel.system('make all')
        raise 'Failed to build the USB cable driver.'
      end
      FileUtils.cp('libusb-driver.so', usb_cable_driver_path)
    end
    FileUtils.rm_r 'usb-driver'
    
    # Create the udev rules for the Xilinx connected via the USB cable.
    FileUtils.mkdir_p '/etc/udev/rules.d'
    File.open('/etc/udev/rules.d/71-xilinx-usb-cable.rules', 'w') do |f|
      f.write 'ACTION=="add", SUBSYSTEMS=="usb", ATTRS{idVendor}=="03fd", MODE="666"'
    end
    unless Kernel.system('/etc/init.d/udev restart')
      raise 'Failed to restart udev'
    end
    
    # Create the udev rules for flashing the USB firmware on the Xilinx board.
    udev_fw_rules = File.read File.join(xilinx_bin_path, 'xusbdfwu.rules')
    [['TEMPNODE', 'tempnode'], ['SYSFS', 'ATTRS'],
     ['BUS', 'SUBSYSTEMS']].each { |from, to| udev_fw_rules.gsub! from, to }
    udev_fw_file = '/etc/udev/rules.d/71-xilinx-usb-firmware-upload.rules'
    File.open(udev_fw_file, 'w') { |f| f.write udev_fw_rules }

    # Copy the firmware files to the appropriate locations.
    Dir.glob(File.join(xilinx_bin_path, 'xusb*.hex')).each do |file|
      FileUtils.cp file, '/usr/share'
    end
  end  
end  # module Scratchpad::Fpga::Provision
  
end  # namespace Scratchpad::Fpga

end  # namespace Scratchpad