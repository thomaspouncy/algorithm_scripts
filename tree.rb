#! /usr/bin/env ruby

class Node
  attr_accessor :parent_node, :children, :value

  def initialize(node_value)
    self.value = node_value
    self.parent_node = nil
    self.children = [$nil_node]
  end

  def childless?
    self.children[0] == $nil_node
  end

  def add_child_node(node)
    if childless?
      self.children[0] = node
    else
      self.children << node
    end
  end
end

$nil_node = Node.new(nil)

class Tree
  attr_accessor :nodes, :root_node

  def initialize(node=$nil_node)
    self.root_node = node
    self.nodes = []
    self.nodes << node unless node == $nil_node
  end

  def add_child_to_node(node,value)
    child = Node.new(value)
    if node.nil?
      self.root_node = child
    else
      node.add_child_node(child)
    end
    self.nodes << child

    return child
  end

  def to_s
    strs = [root_node.value.to_s]
    strs += draw_from_node(root_node,'')
    strs.each do |str|
      puts str
    end
  end

  def draw_from_node(node,indent_str)
    return [] if node.childless?

    strs = []
    node.children.each do |child|
      strs << indent_str + "+---" + child.value.to_s
      if child == node.children.last
        strs += draw_from_node(child,(indent_str + "    "))
      else
        strs += draw_from_node(child,(indent_str + "|   "))
        strs << indent_str + "|"
      end
    end
    return strs
  end
end
