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
  #   min_leaf_count:: the minimum number of leaf nodes in the tree
  #   initial_leaf:: the initial value for the tree leaves
  def self.empty_tree(min_leaf_count, initial_leaf)
    leaf_count = self.leaf_count(min_leaf_count)
    
    nodes = Array.new(node_count(min_leaf_count) + 1)
    0.upto(leaf_count - 1) { |i| nodes[leaf_count + i] = initial_leaf.dup }
    (leaf_count - 1).downto(1) do |i|
      nodes[i] = HashTree.node_hash i, nodes[HashTree.left_child(i)],
                                    nodes[HashTree.right_child(i)]
    end
    self.new leaf_count, nodes
  end
  
  # The number of leaves in a tree with a given minimum leaf count.
  def self.leaf_count(min_leaf_count)
    count = 1
    count *= 2 while count < min_leaf_count
    count
  end
  
  # The number of nodes in a tree with a given minimum leaf count.
  def self.node_count(min_leaf_count)
    leaf_count(min_leaf_count) * 2 - 1
  end
    
  # Creates a new hash tree.
  #
  # This method should not be used directly. Instead, use HashTree#empty_tree or
  # Hash#from_disk.
  def initialize(leaf_count, nodes)
    @leaf_count = leaf_count
    @nodes = nodes
  end
  
  # The number of leaves in this tree.
  def leaf_count
    @leaf_count
  end
  
  # The number of nodes in a tree.
  #
  # Remeber that node indexing starts at 1.
  def node_count
    @nodes.length - 1
  end
  
  # The hash value in a node.
  #
  # Args:
  #   node_id:: the number of the node whose hash is retrieved
  #
  # Returns a string containing the hash for the desired node.
  def [](node_id)
    if node_id <= 0 || node_id >= @leaf_count * 2
      raise InvalidNodeId, "Invalid node id #{node_id.inspect}"
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
      next if leaf_node?(node)
      
      @nodes[node] = HashTree.node_hash node, @nodes[HashTree.left_child(node)],
                                        @nodes[HashTree.right_child(node)]
    end
    self
  end
  
  # Verifies the tree's integrity.
  #
  # Raises an error if the tree fails the integrity check.
  #
  # Returns self if the tree passes the integrity check.
  #
  # This method is useful when reading the tree from disk. When used through the
  # API, the tree should always remain valid.
  def verify
    1.upto(@leaf_count - 1) do |node|
      next if @nodes[node] ==
          HashTree.node_hash(node, @nodes[HashTree.left_child(node)],
                                   @nodes[HashTree.right_child(node)])
      raise "Tree integrity verification failed"    
    end
    self
  end
    
  # The set of nodes needed to update or verify the value of a leaf.
  def leaf_update_path(leaf_id)
    deps = []
    visit_path_to_root leaf_id do |node|
      deps << node
      deps << HashTree.sibling(node) unless node == 1
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
      node = HashTree.parent(node)
    end
    self
  end
  
  # True if a node number points to a leaf node.
  #
  # Args:
  #   node_id:: a node number  
  def leaf_node?(node_id)
    @leaf_count < node_id
  end

  # The node number for a leaf node.
  #
  # Args:
  #   leaf_id:: the number of the leaf whose node number is desired (0-based) 
  def leaf_node_id(leaf_id)
    @leaf_count + leaf_id
  end

  # 
  def self.node_hash(node_offset, left_child_hash, right_child_hash)
    Crypto.crypto_hash [[node_offset].pack('N'),
                        left_child_hash, right_child_hash].join
  end
  
  # The node number of a node's left child.
  def self.left_child(node)
    node << 1  # node * 2
  end
  
  # The node number of a node's right child.
  def self.right_child(node)
    (node << 1) | 1  # node * 2 + 1
  end

  # The node number of a node's sibling.
  #
  # The sibling of a node is the parent's other child.
  def self.sibling(node)
    node ^ 1
  end
  
  # The node number of a node's parent.
  def self.parent(node)
    node >> 1  # node / 2
  end
  
  # True if two node numbers represent nodes with the same parent.
  def self.siblings?(node, other_node)
    node ^ other_node == 1
  end
  
  # True if the node is the left child of its parent.
  def self.left_child?(node)
    (node & 1) == 0  # node % 2 == 0
  end
  
  # True if the node is the right child of its parent.
  def self.right_child?(node)
    (node & 1) == 1  # node % 2 == 1
  end  
end  # class Scratchpad::HashTree


# Namespace for the exceptions raised by HashTree.
module Scratchpad::HashTree::Exceptions
  # Raised when an argument contains an invalid hash tree node number.
  class InvalidNodeId < IndexError
    
  end
end

# :nodoc: fold exceptions namespace into HashTree
class Scratchpad::HashTree
  include Scratchpad::HashTree::Exceptions
end

end  # namespace Scratchpad
