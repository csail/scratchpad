# :nodoc: namespace
module Scratchpad


# Limited view of a hash tree suitable for implementation in an on-chip cache.
#
# The algorithms in this class are intended to be implemented directly in
# hardware. Therefore, they are optimized for simplicity. Along the same lines,
# the methods raise exceptions when fed bad input, because the trusted hardware
# treat bad input as an attack, and get itself offline.
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
  def initialize(capacity, root_hash, leaf_count)
    @leaf_count = leaf_count  # NOTE: this will always be a power of 2
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
  
  # The hash of the tree's root node.
  def root_hash
    @node_hashes[0]
  end
  
  # Verifies that a cache entry matches expected values.
  #
  # Args:
  #   entry:: the number of the cache entry to verify (0-based)
  #   node_id:: the number of the node that should be contained in the entry
  #   node_hash:: the node hash that should be contained in the entry
  #
  # Raises:
  #   InvalidEntry:: entry points to an invalid cache entrie
  #   UnverifiedEntry:: the entry doesn't have the verified flag set
  #   IncorrectNodeHash:: the entry's contents doesn't match the arguments
  #
  # Returns self.
  def check_hash(entry, node_id, node_hash)
    check_entry entry
    unless @verified[entry]
      raise UnverifiedEntry, "Entry #{entry} is not verified"
    end
    unless @node_ids[entry] == node_id and @node_hashes[entry] == node_hash
      raise IncorrectNodeHash, "Incorrect node_id or node_hash"
    end
    self
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
  #   InvalidEntry:: entry or old_parent_entry point to invalid cache entries
  #   InvalidNodeId:: node_id is an invalid hash tree node number
  #   InvalidUpdatePath:: entry is validated, and old_parent_entry does not
  #                       store the parent node of entry's node
  #   DuplicateChild:: entry is validated, and its node has at least one child
  #                    stored in a validated cache entry
  #
  # A node's entry can only be overwritten if none of the node's children is
  # cached. When loading a new node in an entry, the old node's parent is
  # updated to reflect that its child is missing. The entry's verified flag is
  # cleared after it is a assigned a new value.
  def load_entry(entry, node_id, node_hash, old_parent_entry)
    check_entry entry
    if node_id <= 1 || node_id >= 2 * @leaf_count
      raise InvalidNodeId, "Invalid node id #{node_id.inspect}"
    end
    if @verified[entry]            
      check_entry old_parent_entry
      if @left_child[entry] or @right_child[entry]
        raise DuplicateChild, "The entry's node has at least one child cached"
      end
      
      old_node_id = @node_ids[entry]
      if @node_ids[old_parent_entry] != old_node_id / 2
        raise InvalidUpdatePath, "old_parent_entry does not store parent node"
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
    @left_child[entry] = @right_child[entry] = false
  end
  
  # Verifies the values of a node's children.
  #
  # Args:
  #   parent:: the number of the entry holding the parent node (0-based)
  #   left_child:: the number of the entry holding the left child (0-based) 
  #   right_child:: the number of the entry holding the right child (0-based)
  #
  # Raises:
  #   InvalidEntry:: parent, left_child, or right_child point to invalid entries
  #                  in the cache
  #   UnverifiedEntry:: the node in the parent entry is not verified
  #   InvalidUpdatePath:: the nodes stored in left_child and right_child aren't
  #                       the children of the node in parent
  #   DuplicateChild:: a child is not verified, but the parent's corresponding
  #                    flag shows there is another verified entry for that child
  #                    in the cache
  #   RuntimeError:: the parent's hash does not match the children's hashes
  #
  # If the method succeeds, the verified flags will be set for both children.
  # The method correctly handles situations where a child was already verified. 
  def verify_children(parent, left_child, right_child)
    check_entry parent
    check_entry left_child
    check_entry right_child
  
    raise UnverifiedEntry, "Parent entry not validated" unless @verified[parent]
    unless @node_ids[left_child] == @node_ids[parent] * 2
      raise InvalidUpdatePath,
            "Incorrect left child entry #{left_child} for #{parent}"
    end
    unless @node_ids[right_child] == @node_ids[parent] * 2 + 1
      raise InvalidUpdatePath,
            "Incorrect right child entry #{right_child} for #{parent}"
    end
    unless @verified[left_child] == @left_child[parent]
      raise DuplicateChild, "Duplicate left child node"
    end
    unless @verified[right_child] == @right_child[parent]
      raise DuplicateChild, "Duplicate right child node"
    end
    
    parent_hash = HashTree.node_hash @node_ids[parent],
        @node_hashes[left_child], @node_hashes[right_child]
    unless @node_hashes[parent] == parent_hash
      raise IncorrectNodeHash, "Verification failed"
    end
    @left_child[parent] = @right_child[parent] = true
    @verified[left_child] = @verified[right_child] = true
  end
  
  # Updates the cache to reflect a change in a leaf node value.
  #
  # Args:
  #   update_path:: array of numbers of cache entries holding all the nodes
  #                 needed to update the root hash; entries at even positions
  #                 (0, 2, 4 etc.) must contain the nodes on the path from the
  #                 updated leaf to the root; entries at odd positions must
  #                 contain the siblings of the entries pointed by the preceding
  #                 positions; can be obtained from HashTree#leaf_update_path
  #   new_value:: the new hash value for the leaf node
  #
  # Raises:
  #   InvalidEntry:: entry or one of the elements of root_path does not point to
  #                  a valid cache entry
  #   InvalidUpdatePath:: update_path does not meet the conditions specified
  #                       in the argument description 
  #   UnverifiedEntry:: a cache entry listed on update_path is not verified
  #
  # Returns self.
  def update_leaf_value(update_path, new_value)
    update_path.each { |path_entry| check_entry path_entry }    
    check_update_path update_path
    
    @node_hashes[update_path.first] = new_value
    visit_update_path update_path do |hot_entry, cold_entry, parent_entry|
      hot_node = @node_ids[hot_entry]
      cold_node = @node_ids[cold_entry]
      parent_node = @node_ids[parent_entry]
      @node_hashes[parent_entry] = if hot_node < cold_node
        HashTree.node_hash parent_node, @node_hashes[hot_entry],
                                        @node_hashes[cold_entry]
      else
        HashTree.node_hash parent_node, @node_hashes[cold_entry],
                                        @node_hashes[hot_entry]      
      end
    end
    self
  end
    
  # Checks that an entry number points to a valid entry in the cache.
  #
  # Args:
  #   entry:: the entry number to be verified
  #
  # Raises:
  #   InvalidEntry:: if the entry number is invalid
  #
  # This method is called by public methods to validate their arguments. The
  # method can be made unnecessary in the FPGA implementation, if the cache
  # holds 2^n entries (only n bits will be read from the entry arguments).
  def check_entry(entry)
    if entry < 0 || entry >= @capacity
      raise InvalidEntry, "Invalid cache entry #{entry.inspect}"
    end
  end
  private :check_entry
  
  # Verifies the validity of an update path.
  #
  # The return value is unspecified. 
  #
  # See update_leaf_value for a description of the path structure, verification
  # process, and exceptions that can be raised.
  def check_update_path(update_path)
    if @node_ids[update_path.first] < @leaf_count
      raise InvalidUpdatePath, "Update path does not start at a leaf"
    end
    if @node_ids[update_path.last] != 1
      raise InvalidUpdatePath, "Update path does not contain root node"
    end
    
    visit_update_path update_path do |hot_entry, cold_entry, parent_entry|
      if @node_ids[hot_entry] ^ @node_ids[cold_entry] != 1
        raise InvalidUpdatePath,
              "Path contains non-siblings #{hot_entry} and #{cold_entry}"
      end
      unless @node_ids[hot_entry] / 2 == @node_ids[parent_entry]
        raise InvalidUpdatePath,
              "Path entry #{parent_entry} is not parent for #{hot_entry}"
      end
      
      # NOTE: the checks below will not run for the root node; that's OK, the
      #       root node is always verified, as it never leaves the cache
      unless @verified[hot_entry]
        raise UnverifiedEntry, "Unverified entry #{hot_entry}"
      end
      unless @verified[cold_entry]
        raise UnverifiedEntry, "Unverified entry #{cold_entry}"
      end
    end
  end
  private :check_update_path

  # Yields every tree level in a path used to update a leaf's value.
  #
  # Args:
  #   update_path:: array of cache entries, as described in update_leaf_value
  #
  # Yields:
  #   hot_entry:: entry containing a node whose hash will be re-computed
  #   cold_entry:: entry containing the sibling of the node in hot_entry
  #   parent_entry:: entry containing the parent of the node in hot_entry
  #
  # The return value is not specified.
  def visit_update_path(update_path)
    0.upto(update_path.length / 2 - 1) do |i|
      hot_entry = update_path[i * 2]  # Node to be updated.
      cold_entry = update_path[i * 2 + 1]  # Sibling of the node to be updated.
      parent_entry = update_path[i * 2 + 2]  # Parent of the node to be updated.
    
      yield hot_entry, cold_entry, parent_entry
    end
  end
  private :visit_update_path
end  # class Scratchpad::HashTreeCache


# Namespace for the exceptions raised by HashTreeCache.
module Scratchpad::HashTreeCache::Exceptions
  # Raised when an argument points to a non-existent cache entry.
  class InvalidEntry < IndexError
    
  end
  
  # Raised when a cache is about to get two entries verified for the same node.
  class DuplicateChild < SecurityError
  
  end

  # Raised when a parent's hash doesn't match its children's hashes.
  class IncorrectNodeHash < SecurityError
    
  end
  
  # Raised when a 
  class InvalidNodeId < IndexError
    
  end
  
  # Raised when the path to update_leaf_value is broken for some reason.
  class InvalidUpdatePath < SecurityError
    
  end
  
  # Raised when an argument points to an unverified entry, but the operation
  # requires a verified entry.
  class UnverifiedEntry < SecurityError
    
  end
end  # namespace Scratchpad::HashTreeCache::Exceptions

# :nodoc: fold exceptions namespace into HashTreeCache
class Scratchpad::HashTreeCache
  include Scratchpad::HashTreeCache::Exceptions
end

end  # class Scratchpad
