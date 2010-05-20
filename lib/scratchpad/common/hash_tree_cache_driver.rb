require 'set'

# :nodoc: namespace
module Scratchpad

# Manages a HashTreeCache.
class HashTreeCacheDriver
  # Creates a new cache driver.
  #
  # Args:
  #   hash_tree:: the hash tree being cached
  #   cache_capacity:: the number of lines in the cache
  def initialize(hash_tree, cache_capacity)
    @tree = hash_tree
    
    @cache_lines = Array.new(cache_capacity) do
      { :node => 0, :left => nil, :right => nil }
    end
    @tree_nodes = { 0 => 1 }
  end
  
  # The operations that will get a leaf node loaded into the cache.
  #
  # Args:
  #   leaf_id:: the number of the leaf to be loaded (0-based) 
  #
  # Returns a Hash with the following keys:
  #   :line:: the cache line that will hold the verified leaf
  #   :ops:: an array following the specifications for perform_ops
  def load_leaf(leaf_id)
    nodes = missing_nodes_for_read(leaf_id)
    ops, mapped = load_nodes nodes[:load], nodes[:keep], [leaf_id]
    { :line => mapped.first, :ops => ops }
  end
  
  # The operations that will load the nodes needed to perform a leaf update.
  #
  # Args:
  #   leaf_id:: the number of the leaf to be updated (0-based) 
  #
  # Returns a Hash with the following keys:
  #   :path:: the path of cache lines needed to update the leaf
  #   :ops:: an array following the specifications for perform_ops
  def load_update_path(leaf_id)
    nodes = missing_nodes_for_write(leaf_id)
    ops, mapped = load_nodes nodes[:load], nodes[:keep], nodes[:path]
    { :path => mapped, :ops => ops }
  end
  
  # Updates the driver state to reflect cache operations.
  #
  # Args:
  #   ops:: an array with one Hash per operation, with the following keys:
  #         :op:: the operation to be performed, :load or :verify
  #         :line:: (load) the cache line number
  #         :node:: (load) the node number
  #         :old_parent_line:: (load) the cache line number for the old parent
  #         :parent:: (verify) the cache line number for the parent node
  #         :left:: (verify) the cache line number for the left child
  #         :right:: (verify) the cache line number of the right child
  #
  # The method is only guaranteed to accurately update the driver's state when
  # given an array operations produced by calls to this driver.
  def perform_ops(operations)
    operations.each do |op|
      case op[:op]
      when :load
        old_node = @cache_lines[op[:line]][:node]
        @tree_nodes.delete old_node
        if HashTree.left_child? old_node
          @cache_lines[op[:old_parent_line]][:left] = nil
        else
          @cache_lines[op[:old_parent_line]][:right] = nil
        end
        
        @cache_lines[op[:line]][:id] = op[:node]
        @cache_lines[op[:line]][:left] = nil
        @cache_lines[op[:line]][:right] = nil
        @tree_nodes[op[:node]] = op[:line]
      when :verify
        @cache_lines[op[:parent]][:left] = op[:left]
        @cache_lines[op[:parent]][:right] = op[:right]
      end
    end
  end
  
  # The nodes that must be loaded in the tree to validate a leaf.
  #
  # Args:
  #   leaf_id:: the number of the leaf to be validated
  #
  # Returns a Hash with the following keys:
  #   :keep:: array of nodes that need to stay in the tree, sorted
  #   :load:: array of nodes to be loaded in the tree, sorted
  def missing_nodes_for_read(leaf_id)
    nodes = []
    anchor = nil
    @tree.visit_path_to_root(leaf_id) do |node|
      if @tree_nodes.has_key? node
        anchor = node
        break
      end
      nodes << node
      sibling = HashTree.sibling node
      nodes << sibling unless @tree_nodes.has_key?(sibling)
    end
    { :keep => [anchor], :load => nodes.reverse }
  end
  
  # The nodes that must be loaded in the tree to update a leaf.
  #
  # Args:
  #   leaf_id:: the number of the leaf to be updated
  #
  # Returns a Hash with the following keys:
  #   :keep:: array of nodes that need to stay in the tree, sorted
  #   :load:: array of nodes to be loaded in the tree, sorted
  #   :path:: the original update path
  def missing_nodes_for_write(leaf_id)
    path = @tree.leaf_update_path(leaf_id)
    keep, load = path.partition do |node|
      @tree_nodes.hash_key?(node)
    end
    { :keep => keep, :load => load, :path => path }
  end
  
  # The operations that will load a bunch of nodes in the cache.
  #
  # Args:
  #   load_nodes:: the nodes to be loaded in the cache
  #   keep_nodes:: the nodes to be mapped in the cache
  #   map_nodes:: array of nodes to be mapped to cache lines
  #
  # Returns: operations, mapped_lines
  #   operations:: conforms to the specifications of perform_ops
  #   mapped_lines:: cache lines that will be holding the nodes in map_nodes
  def load_nodes(load_nodes, keep_nodes, map_nodes)
    free_lines = find_lines nodes[:load].count, nodes[:keep]
    lines = nodes[:load].zip(free_lines)    
    ops = lines.map do |node, line|
      old_parent_line = @tree_nodes[HashTree.parent(@cache_lines[line][:id])]
      { :op => :load, :line => line, :node => node,
        :old_parent_line => old_parent_line }
    end
    
    new_lines = Hash[*nodes[:load].zip(lines).flatten]
    verified_parents = Set.new([])
    lines.each do |node, line|
      parent_node = HashTree.parent(node)
      
      next if verified_parents.include? parent_node
      verified_parents << parent_node

      parent_line = new_lines[parent_node] || @tree_nodes[parent_node]
      sibling_node = HashTree.sibling(node)
      sibling_line = new_lines[sibling_node] || @tree_nodes[sibling_node]
      if HashTree.left_child?(node)
        ops << { :op => :verify, :parent => parent_line,
                 :left => line, :right => sibling_line }
      else
        ops << { :op => :verify, :parent => parent_line,
                 :left => sibling_line, :right => line }
      end
    end
    
    return ops, map_nodes.map { |node| new_lines[node] }
  end
  
  # Locates lines that should be used to load new nodes.
  #
  # Args:
  #   load_count:: the desired number of lines
  #   keep_lines:: lines that should not be removed from the cache
  #
  # Returns an array of lines.
  def find_lines(load_count, keep_lines)
    
  end  
end  # class Scratchpad::HashTreeCacheDriver

end  # namespace Scratchpad
