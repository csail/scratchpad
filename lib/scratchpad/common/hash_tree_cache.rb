# :nodoc: namespace
module Scratchpad


# Limited view of a hash tree suitable for implementation in an on-chip cache.
#
# The algorithms in this class are intended to be implemented directly in
# hardware. Therefore, they are optimized for simplicity.
#
# The cache is made up of entries, and each entry can hold one node. An entry
# holds a node's number (representing its position in a HashTree), hash value
# (computed with HashTree#node_hash), and the following flags:
#   verified:: if true, this means that the node's hash value is guaranteed to
#              be correct; verification is based on the tree's root hash
#   left_child:: true if and only if the node's left child is present and
#                verified in the cache
#   right_child:: true if and only if the node's right child is present and
#                 verified in the cache
#
# A node cannot be loaded and verified in two entries in the cache, in order to
# avoid replay attacks using stale entries. This is enforced by keeping track of
# which of a node's children are loaded and validated in the cache. See
# set_entry and verify_children for how this invariant is maintained.
class HashTreeCache
  # Create a new hash tree cache.  
  def initialize(root_hash, capacity, leaf_count)
    @leaf_count = leaf_count
    @capacity = capacity

    @node_ids = Array.new capacity, nil
    @node_hashes = Array.new capacity, nil
    @verified = Array.new capacity, false    
    @left_child = Array.new capacity, false
    @right_child = Array.new capacity, false
  
    @node_ids[0] = 1
    @verified[0] = true
    @node_hashes[0] = root_hash
  end
  
  # The number of entries in the cache.
  def entry_count
    @capacity
  end
  
  # Loads a cache entry with a tree node.
  #
  # Args:
  #   entry:: the number of the cache entry to load (0-based)
  #   node_id:: the number of the node to be loaded into the entry (1-based)
  #   node_hash:: the node's hash
  #   old_parent_entry:: the number of the cache entry holding the parent of the
  #                      old node held by this cache entry
  #
  # Raises:
  #   RuntimeError:: entry or old_parent_entry point to invalid cache entries
  #   RuntimeError:: entry is validated, and old_parent_entry does not store the
  #                  parent node of entry's node
  #
  # A node's entry can only be overwritten if none of the node's children is
  # cached. When loading a new node in an entry, the old node's parent is
  # updated to reflect that its child is missing. The entry's verified flag is
  # cleared after it is a assigned a new value.
  def set_entry(entry, node_id, node_hash, old_parent_entry)
    check_entry entry
    check_entry old_parent_entry
    if node_id <= 1 || node_id >= 2 * @leaf_count
      raise "Invalid node id #{node_id.inspect}"
    end
    if @verified[entry]
      old_node_id = @node_ids[entry]
      if @node_ids[old_parent_entry] != old_node_id / 2
        raise "old_parent_entry does not store parent node"
      end
      if old_node_id % 2 == 0
        @left_child[old_parent_entry] = false
      else
        @right_child[old_parent_entry] = false
      end
    end
    @node_ids[entry] = node_id
    @verified[entry] = false
    @node_hashes[entry] = node_hash
  end
  
  # Verifies the values of a node's children.
  #
  # Args:
  #   parent:: the number of the entry holding the parent node (0-based)
  #   left_child:: the number of the entry holding the left child (0-based) 
  #   right_child:: the number of the entry holding the right child (0-based)
  #
  # Raises:
  #   RuntimeError:: parent, left_child, or right_child point to invalid entries
  #                  in the cache
  #   RuntimeError:: the node in the parent entry is not verified
  #   RuntimeError:: a child is not verified, but the parent's corresponding
  #                  flag shows there is another verified entry for that child
  #                  in the cache
  #   RuntimeError:: the parent's hash does not match the children's hashes
  #
  # If the method succeeds, the verified flags will be set for both children.
  # The method correctly handles situations where a child was already verified. 
  def verify_children(parent, left_child, right_child)
    check_entry parent
    check_entry left_child
    check_entry right_child
  
    raise "Parent entry not validated" unless @verified[parent]
    unless @node_ids[left_child] == @node_ids[parent] * 2
      raise "Incorrect left child entry"
    end
    unless @node_ids[right_child] == @node_ids[parent] * 2 + 1
      raise "Incorrect right child entry"
    end
    unless @verified[left_child] == @left_child[parent]
      raise "Duplicate left child node"
    end
    unless @verified[right_child] == @right_child[parent]
      raise "Duplicate right child node"
    end
    
    parent_hash = HashTree.node_hash @node_ids[parent],
        @node_hashes[left_child], @node_hashes[right_child]
    unless @node_hashes[parent] == parent_hash
      raise "Verification failed"
    end
    @verified[left_child] = @verified[right_child] = true
  end
  
  # 
  def update_value(entry, new_value, entry_path)
    # TODO(costan): figure out how to represent the validation path
  end
    
  # Checks that an entry number points to a valid entry in the cache.
  #
  # Args:
  #   entry:: the entry number to be verified
  #
  # Raises:
  #   RuntimeError:: if the entry number is invalid
  #
  # This method is called by public methods to validate their arguments. The
  # method can be made unnecessary in the FPGA implementation, if the cache
  # holds 2^n entries (only n bits will be read from the entry arguments).
  def check_entry(entry)
    if entry < 0 || entry >= entries.length
      raise "Invalid cache entry #{entry.inspect}"
    end
  end
  private :check_entry
end  # class Scratchpad::HashTreeCache

end  # class Scratchpad
