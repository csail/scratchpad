# Binary specification for a high-performance trusted storage system.
module Scratchpad
  
end

require 'scratchpad/common/crypto.rb'
require 'scratchpad/common/disk_helper.rb'
require 'scratchpad/common/hash_tree.rb'
require 'scratchpad/common/hash_tree_cache.rb'
require 'scratchpad/common/hash_tree_cache_driver.rb'
require 'scratchpad/common/hash_tree_on_disk.rb'
require 'scratchpad/ethernet/ping.rb'
require 'scratchpad/ethernet/raw_ethernet.rb'
require 'scratchpad/fpga/provision.rb'
require 'scratchpad/models/client.rb'
require 'scratchpad/models/disk.rb'
require 'scratchpad/models/fpga.rb'
require 'scratchpad/models/manufacturer.rb'
require 'scratchpad/models/server.rb'
require 'scratchpad/models/smartcard.rb'
