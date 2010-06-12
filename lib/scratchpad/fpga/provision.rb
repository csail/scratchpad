require 'fileutils'

# :nodoc: namespace
module Scratchpad
  
# :nodoc: namespace
module Fpga
  
# Methods for provisioning the FPGA.
module Provision
  # Sets up this computer for using the Xilinx USB cable driver.
  #
  # This is more complicated than it seems.
  def self.setup_xilinx_cable
    install_packages
    install_cable_driver
    install_cable_udev_rules
    install_usb_firmware_upload_udev_rules
    reload_udev_rules
  end

  # Installs the OS pakcages needed for building and deploying the cable driver. 
  def self.install_packages
    packages = ['git-core', 'libusb-dev', 'build-essential', 'fxload']
    unless Kernel.system("apt-get install #{packages.join(' ')}")
      raise 'Failed to install packages.'
    end
  end

  # Clone and build the USB cable driver.
  #
  # This method is an implementation detail of setup_xilinx_cable.
  def self.install_cable_driver
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
  end
  
  # Create the udev rules for the Xilinx connected via the USB cable.
  #
  # This method is an implementation detail of setup_xilinx_cable.
  def self.install_cable_udev_rules
    FileUtils.mkdir_p '/etc/udev/rules.d'
    File.open('/etc/udev/rules.d/71-xilinx-usb-cable.rules', 'w') do |f|
      f.write 'ACTION=="add", SUBSYSTEMS=="usb", ATTRS{idVendor}=="03fd", MODE="666"'
    end
  end
  
  # Create the udev rules for flashing the USB firmware on the Xilinx board.
  def self.install_usb_firmware_upload_udev_rules
    udev_fw_rules = File.read File.join(xilinx_bin_path, 'xusbdfwu.rules')
    [['TEMPNODE', 'tempnode'], ['SYSFS', 'ATTRS'],
     ['BUS', 'SUBSYSTEMS']].each { |from, to| udev_fw_rules.gsub! from, to }
    udev_fw_file = '/etc/udev/rules.d/71-xilinx-usb-firmware-upload.rules'
    File.open(udev_fw_file, 'w') { |f| f.write udev_fw_rules }    
  end
  
  # Causes the udev daemon to reload its rules.
  def self.reload_udev_rules
    unless Kernel.system('/etc/init.d/udev restart')
      raise 'Failed to restart udev'
    end    
  end
  
  # Copies the Xilinx USB controller firmware images to.
  def self.install_usb_firmware_images
    Dir.glob(File.join(xilinx_bin_path, 'xusb*.hex')).each do |file|
      FileUtils.cp file, '/usr/share'
    end    
  end
    
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
  
  # Path to the Xilinx USB cable driver.
  def self.usb_cable_driver_path
    File.join xilinx_bin_path, 'libusb-driver.so'
  end  
end  # module Scratchpad::Fpga::Provision
  
end  # namespace Scratchpad::Fpga

end  # namespace Scratchpad
