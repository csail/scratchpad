# :nodoc: namespace
module Scratchpad


# :nodoc: augments HashTree with disk read/writing functionality
class HashTree
  # Restores a hash tree from a disk.
  #
  # Args:
  #   disk:: the disk that the tree was written to
  #   min_leaf_count:: the same value that was given when creating the tree
  #   starting_block:: the starting disk block for the tree data
  #
  # Returns a new HashTree instance initialized from the on-disk data.
  def self.from_disk(disk, min_leaf_count, starting_block)
    node_count = self.node_count min_leaf_count
    nodes_per_block = self.nodes_per_block disk
    nodes = Array.new node_count + 1
    
    node, block = 1, starting_block
    while node < nodes.length
      block_data = disk.read_blocks block, 1
      read_size = [nodes_per_block, nodes.length - node].min
      0.upto(read_size - 1) do |i|
        nodes[node + i] = block_data[i * node_size, node_size]
      end
      node, block = node + read_size, block + 1
    end

    self.new(leaf_count(min_leaf_count), nodes).verify
  end
  
  # Writes a hash tree to a disk.
  #
  # Args:
  #   disk:: the disk that the tree will be written to
  #   starting_block:: the starting disk block for the tree data
  #
  # The return value is unspecified.
  def write_to_disk(disk, starting_block)
    nodes_per_block = self.class.nodes_per_block disk
    
    node, block = 1, starting_block
    while node <= node_count
      write_size = [nodes_per_block, node_count + 1 - node].min
      filler_size = disk.block_size - write_size * self.class.node_size
      
      write = Array.new(write_size + 1)
      0.upto(write_size - 1) { |i| write[i] = self[node + i] }
      write[write_size] = "\0" * filler_size
      disk.write_blocks block, 1, write.join      
      
      node, block = node + write_size, block + 1
    end
  end
  
  # The number of blocks taken by this tree on a disk.
  def blocks_on_disk(disk)
    self.class.blocks_on_disk disk, leaf_count
  end
  
  # The number of blocks taken by a tree on a disk.
  def self.blocks_on_disk(disk, min_leaf_count)
    nodes_per_block = self.nodes_per_block disk
    node_count = self.node_count min_leaf_count
    (node_count + nodes_per_block - 1) / nodes_per_block    
  end
  
  # The number of tree nodes that fit in a disk block.
  #
  # Args:
  #   disk:: the disk that we're performing the computation for.
  def self.nodes_per_block(disk)
    disk.block_size / node_size
  end
  
  def self.node_size
    @node_size ||= Crypto.crypto_hash("0").length
  end

end  # class Scratchpad::HashTree

end  # namespace Scratchpad
