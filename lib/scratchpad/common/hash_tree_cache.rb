# :nodoc: namespace
module Scratchpad


# Limited view of a hash tree suitable for implementation in an on-chip cache.
#
# The algorithms in this class are intended to be implemented directly in
# hardware. Therefore, they are optimized for simplicity.
class HashTreeCache
  # Create a new hash tree cache.  
  def initialize(root_hash, capacity, leaf_count)
    @leaf_count = leaf_count

    # The node number of each cache entry.
    @node_ids = Array.new capacity, nil
    # True for the nodes whose values have been verified.
    @verified = Array.new capacity, false    
    # The node hash for each cache entry.
    @node_hashes = Array.new capacity, nil
    # True if the left child of the node is also valid in the cache.
    @left_child = Array.new capacity, false
    # True if the right child of the node is also valid in the cache.
    @right_child = Array.new capacity, false
  
    @node_ids[0] = 1
    @verified[0] = true
    @node_hashes[0] = root_hash
  end
  
  def set_entry(entry, node_id, node_hash, old_parent_entry)
    check_entry entry
    check_entry old_parent_entry
    if node_id <= 1 || node_id >= 2 * @leaf_count
      raise "Invalid node id #{node_id.inspect}"
    end
    old_node_id = @node_ids[entry]
    if @node_ids[old_parent_entry] != old_node_id / 2
      raise "old_parent_entry does not store parent node"
    end
    if old_node_id % 2 == 0
      @left_child[old_parent_entry] = false
    else
      @right_child[old_parent_entry] = false
    end
    @node_ids[entry] = node_id
    @verified[entry] = false
    @node_hashes[entry] = node_hash
  end
  
  def verify_entries(parent, left_child, right_child)
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
  
  def update_value(entry, new_value, entry_path)
    # TODO(costan): figure out how to represent the validation path
  end
  
  def check_entry(entry)
    if entry < 0 || entry >= entries.length
      raise "Invalid cache entry #{entry.inspect}"
    end
  end
  private :check_entry
end  # class Scratchpad::HashTreeCache

end  # class Scratchpad
