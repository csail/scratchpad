require 'set'

# :nodoc: namespace
module Scratchpad


# Model for an authentication tree.
#
# The server CPU maintains the full authentication tree in untrusted storage.
# The trusted FPGA has a restricted view of the tree.
class HashTree
  # Creates an empty hash tree.
  #
  # Args:
  #   leaf_count:: the minimum number of leaf nodes in the tree
  #   initial_leaf:: the initial value for the tree leaves
  def initialize(leaf_count, initial_leaf)
    @leaf_count = 1
    @leaf_count *= 2 while @leaf_count < leaf_count
    
    @nodes = Array.new(@leaf_count * 2)
    0.upto(@leaf_count - 1) { |i| @nodes[@leaf_count + i] = initial_leaf.dup }
    (@leaf_count - 1).downto(0) do |i|
      @nodes[i] = HashTree.node_hash i, @nodes[HashTree.left_child(i)],
                                     @nodes[HashTree.right_child(i)]
    end
  end
  
  # The number of leaves in this tree.
  def leaf_count
    @leaf_count
  end
  
  # The hash value in a node.
  #
  # Args:
  #   node_id:: the number of the node whose hash is retrieved
  #
  # Returns a string containing the hash for the desired node.
  def [](node_id)
    if node_id < 0 || node_id >= @leaf_count * 2
      raise "Invalid node id #{node_id.inspect}"
    end
    @nodes[node_id]
  end
  
  # The hash value for the tree's root node.
  def root_hash
    self[1]
  end

  # Updates the value of a leaf.
  #
  # Args:
  #   leaf_id:: the leaf whose value is updated
  #   new_value:: the leaf's new value
  #
  # Returns self.
  def update(leaf_id, new_value)
    @nodes[@leaf_count + leaf_id] = new_value
    visit_path_to_root(leaf_id) do |node|
      @nodes[node] = HashTree.node_hash node, @nodes[HashTree.left_child(node)],
                                        @nodes[HashTree.right_child(node)]
    end
    self
  end
  
  # Verifies the tree's integrity.
  #
  # Raises an error if the tree fails the integrity check.
  #
  # This method is useful when reading the tree from disk. When used through the
  # API, the tree should always remain valid.
  def verify
    1.upto(@leaf_count - 1) do |node|
      next if @nodes[node] ==
          HashTree.node_hash(node, @nodes[node * 2], @nodes[node * 2 + 1])
      raise "Tree integrity verification failed"    
    end
  end
    
  # The set of nodes needed to update or verify the value of a leaf.
  def leaf_update_path(leaf_id)
    deps = []
    visit_path_to_root leaf_id do |node|
      deps << node
      deps << (node ^ 1) unless node == 1
    end
    deps
  end
  
  # Yields the nodes on the path from a leaf to the root.
  #
  # Args:
  #   leaf_id:: the leaf starting the path
  #
  # Returns self.
  def visit_path_to_root(leaf_id)
    node = @leaf_count + leaf_id
    while node > 0
      yield node
      node /= 2
    end
    self
  end
  private :visit_path_to_root
  
  # True if a node number points to a leaf node.
  #
  # Args:
  #   leaf_id:: a node number  
  def leaf_node?(node_id)
    @leaf_count < node_id
  end

  # 
  def self.node_hash(node_offset, left_child_hash, right_child_hash)
    Crypto.crypto_hash [[node_offset].pack('N'),
                        left_child_hash, right_child_hash].join
  end
  
  def self.left_child(node)
    node * 2  
  end
  
  def self.right_child(node)
    node * 2 + 1
  end
end  # class Scratchpad::HashTree

end  # namespace Scratchpad
