#! /usr/bin/env ruby

require "benchmark"

$board_height = ARGV[0].to_i
$board_width = ARGV[1].to_i
$vertex_density = ARGV[2].to_f/100
$edge_frequency = ARGV[3].to_i
times_to_repeat = ARGV[4].to_i

Cell = Struct.new(:value,:next)

$nil_cell = Cell.new(nil,nil)

class LinkedList
  attr_accessor :head, :tail

  def initialize()
    # O(1)
    self.head = self.tail = $nil_cell
  end

  def push(value)
    # O(1)
    new_cell = Cell.new(value,$nil_cell)
    
    if head == $nil_cell
      self.head = self.tail = new_cell
    else
      self.tail.next = new_cell
      self.tail = new_cell
    end

    return head 
  end

  def pop
    # O(1)
    raise "Stack overflow" if head == $nil_cell
    popped_cell = head
    self.head = popped_cell.next

    return popped_cell
  end

  def each
    # O(1)
    return enum_for(:each) unless block_given?

    i = head
    while i != $nil_cell
      yield i.value
      i = i.next
    end
  end
end

class Board
  attr_accessor :y_slots, :x_slots, :empty_slot_char, :border_char, :display_matrix

  def initialize(options={})
    # overall perf: O(y) Space: O(y*x)

    self.y_slots = options[:y_slots] || 10
    self.x_slots = options[:x_slots] || 10
    self.empty_slot_char = options[:empty_slot_char] || '.'
    self.border_char = options[:border_char] || 'x'

    initialize_display_matrix
  end 

  def height
    # O(1)
    y_slots*3+2
  end

  def width
    # O(1)
    x_slots*3+2
  end

  def initialize_display_matrix
    # overall perf: O(y) Space: O(y*x)

    # perf: O(1) Space: O(y)
    new_matrix = Array.new(height)

    # perf: O(1) Space: O(x)
    new_matrix[0] = new_matrix[height-1] = Array.new(width,border_char)    

    # perf: O(y) Space: O(y*x)
    i = 1
    while i <= y_slots
      new_matrix[i*3-2] = [border_char] + ([' ',' ',' '] * x_slots) + [border_char]
      new_matrix[i*3-1] = [border_char] + ([' ',empty_slot_char,' '] * x_slots) + [border_char]
      new_matrix[i*3] = [border_char] + ([' ',' ',' '] * x_slots) + [border_char]
      
      i += 1
    end
    
    # perf: O(1)
    self.display_matrix = new_matrix
  end

  def section_index_transformation(x,y,section)
    # O(1)
    x_index = y_index = nil
    case section
    when 'center'
      x_index = x*3-1
      y_index = y*3-1
    when 'top'
      x_index = x*3-1
      y_index = y*3-2
    when 'bottom'
      x_index = x*3-1
      y_index = y*3
    when 'left'
      x_index = x*3-2
      y_index = y*3-1
    when 'right'
      x_index = x*3
      y_index = y*3-1
    when 'topleft'
      x_index = x*3-2
      y_index = y*3-2
    when 'topright'
      x_index = x*3
      y_index = y*3-2
    when 'bottomleft'
      x_index = x*3-2
      y_index = y*3
    when 'bottomright'
      x_index = x*3
      y_index = y*3
    else
      raise "Invalid section: #{section}"
    end

    return x_index, y_index
  end

  def char_at_position(x,y,section)
    # O(1)

    x_index, y_index = section_index_transformation(x,y,section)
    display_matrix[y_index][x_index]
  end

  def slot_empty?(x,y)
    # O(1)

    char_at_position(x,y,"center") == empty_slot_char
  end

  def direction_empty?(pos,dir)
    # O(1)

    char_at_position(pos.first,pos.last,dir) == ' '
  end

  def draw
    # O(y) (NOTE: this depends on the performance of join)
    display_matrix.each do |curr_line|
      puts curr_line.join('')
    end
  end

  def update_position(position,char,section)
    # O(1)

    x_index, y_index = section_index_transformation(position.first,position.last,section)

    display_matrix[y_index][x_index] = char
  end

  def set_slot(position,char)
    update_position(position,char,"center")
  end

  def add_line(start_position,end_position)
    # on average O(x*y)
    return if start_position == end_position
    
    if start_position.last == end_position.last
      lower = higher = nil
      if start_position.first < end_position.first 
        lower = start_position.first
        higher = end_position.first
      else
        lower = end_position.first
        higher = start_position.first
      end

      update_position([lower,start_position.last],'-',"right")
      update_position([higher,start_position.last],'-',"left")

      # O(sqrt(y^2 + x^2)) in worst case. On average, O(x*y) 
      i = lower+1
      while i < higher
        update_position([i,start_position.last],'-',"left")
        update_position([i,start_position.last],'-',"right")
      
        i += 1
      end
    elsif start_position.first == end_position.first
      lower = higher = nil
      if start_position.last < end_position.last 
        lower = start_position.last
        higher = end_position.last
      else
        lower = end_position.last
        higher = start_position.last
      end

      update_position([start_position.first,lower],'|',"bottom")
      update_position([start_position.first,higher],'|',"top")

      i = lower+1
      while i < higher
        update_position([start_position.first,i],'|',"top")
        update_position([start_position.first,i],'|',"bottom")
      
        i += 1
      end
    else
      lower = higher = nil
      if start_position.first < end_position.first
        lower = start_position
        higher = end_position
      else
        lower = end_position
        higher = start_position
      end

      if lower.last < higher.last
        update_position(lower,'\\','bottomright')
        update_position(higher,'\\','topleft')

        i = lower.first + 1
        j = lower.last + 1
        while i < higher.first
          update_position([i,j],'\\','topleft')
          update_position([i,j],'\\','bottomright')

          i += 1
          j += 1
        end
      else
        update_position(lower,'/','topright')
        update_position(higher,'/','bottomleft')

        i = lower.first + 1
        j = lower.last - 1
        while i < higher.first
          update_position([i,j],'/','topright')
          update_position([i,j],'/','bottomleft')

          i += 1
          j -= 1
        end

      end
    end
  end
end

class Vertex
  attr_accessor :position, :display_name

  def initialize(position_array,display_name)
    # O(1)
    raise "Invalid position" unless position_array.is_a?(Array) && position_array.length == 2 
    raise "Positions must be integers" unless position_array.first.is_a?(Integer) && position_array.last.is_a?(Integer)
    raise "Positions must be strictly positive" unless position_array.first > 0 && position_array.last > 0
    
    raise "Invalid display name" if display_name.nil?
    self.position = position_array 
    self.display_name = display_name
  end

  def self.generate_random_vertex(board,name)
    # O(1)

    begin
      x_pos = rand(board.x_slots)+1
      y_pos = rand(board.y_slots)+1

      new_vertex = Vertex.new([x_pos,y_pos],name)
    end until board.slot_empty?(x_pos,y_pos)
    
    board.set_slot(new_vertex.position,new_vertex.display_name.to_s)
    return new_vertex
  end

  def self.check_direction_and_alignment(a,b)
    # O(1)
    return nil, nil if a == b

    aligned = false
    direction = ''

    if a.position.last < b.position.last
      direction = "bottom"
    elsif a.position.last > b.position.last
      direction = "top"
    else
      aligned = true
    end

    if a.position.first < b.position.first
      direction += "right"
    elsif a.position.first > b.position.first
      direction += "left"
    else
      aligned = true
    end

    if (a.position.first - b.position.first).abs == (a.position.last - b.position.last).abs
      # diagonally aligned case
      aligned = true
    end

    return direction, aligned
  end

  def ==(other_vertex)
    # O(1)
    return false if other_vertex.nil?
    self.position == other_vertex.position
  end

  def <=>(other_vertex)
    # O(1)
    if position.last == other_vertex.position.last
      return position.first <=> other_vertex.position.first
    else
      return position.last <=> other_vertex.position.last
    end
  end
end

class Edge
  attr_accessor :vertex_a, :vertex_b, :directed, :weight

  def initialize(options)
    # O(1)
    self.vertex_a = options[:vertex_a]
    self.vertex_b = options[:vertex_b]
    raise "Invalid vertices" unless vertex_a.is_a?(Vertex) && vertex_b.is_a?(Vertex)

    self.directed = options[:directed] || false
    self.weight = options[:weight] || 1
    raise "Invalid weight" unless weight.is_a?(Integer)
  end

  def ==(other_edge)
    # O(1)
    (vertex_a == other_edge.vertex_a && vertex_b == other_edge.vertex_b) ||
    (directed != true && other_edge.directed != true && vertex_a == other_edge.vertex_b && vertex_b == other_edge.vertex_a)
  end

  def self.generate_random_edges_for_vertex(vertex_a,vertices,board)
    # O(ef)
    new_edges = []
    sampled_vertices = vertices.sample($edge_frequency)

    sampled_vertices.each do |vertex_b|
      unless vertex_b == vertex_a
        # O(1)
        direction, aligned = Vertex.check_direction_and_alignment(vertex_a,vertex_b)
        # O(1)
        if aligned && board.direction_empty?(vertex_a.position,direction)
          new_edge = Edge.new(:vertex_a=>vertex_a,:vertex_b=>vertex_b)
          new_edges << new_edge

          # O(1)
          board.add_line(vertex_a.position,vertex_b.position)
        end
      end
    end

    return new_edges
  end
end

class Graph
  attr_accessor :vertices, :edges, :board, :adjacency_list

  def initialize(options)
    # O(nv)
    if !options[:vertices].nil?
      self.vertices = options[:vertices]
      self.edges = options[:edges]
      build_adjacency_list
    else
      self.board = options[:board] || Board.new()
      num_vertices = options[:num_vertices] || ($vertex_density)*($board_width*$board_height)
      num_vertices = num_vertices.to_i
      self.vertices = []
      self.edges = []
      self.adjacency_list = {}

      # generate random vertices when no vertices are given
      # O(nv)
      names = (1..9).to_a + ('a'..'z').to_a+('A'..'Z').to_a
      num_names = names.length

      i = 0
      num_vertices.times do 
        vertex = Vertex.generate_random_vertex(board,names[i%num_names])
        self.vertices << vertex
        self.adjacency_list[vertex] = LinkedList.new()
        i += 1
      end

      # O(nv*ef) = O(nv)
      vertices.each do |vertex|
        new_edges = Edge.generate_random_edges_for_vertex(vertex,vertices,board)
       
        self.edges += new_edges
        # number of edges should be constant based on edge frequency
        new_edges.each do |edge|
          self.adjacency_list[vertex].push(edge.vertex_b)
          unless edge.directed == true
            self.adjacency_list[edge.vertex_b].push(vertex)
          end
        end
      end
    end
  end

  def build_adjacency_list
    # O(nv+ne)

    adj = {}
    vertices.each do |vertex|
      adj[vertex] = LinkedList.new()
    end

    edges.each do |edge|
      adj[edge.vertex_a].push(edge.vertex_b)
      unless edge.directed == true
        adj[edge.vertex_b].push(edge.vertex_a)
      end
    end

    self.adjacency_list = adj
  end
end

vertices = []
edges = []
graph = nil

# nv = O(y*x)
# ne = 8*nv*freq = O(y*x)
# Overall should be O(x*y)
# Benchmark.bmbm do |x|
  # times_to_repeat.times do
    # x.report("initializing board") do
      # O(y)
      $main_board = Board.new(:x_slots=>$board_width,:y_slots=>$board_height)
    # end

    # x.report("initializing graph") do
      # O(y*x)
      graph = Graph.new(:board=>$main_board)
    # end

    # if times_to_repeat == 1
      # x.report("drawing board") do
        # O(y)
        $main_board.draw
      # end
    # end
  # end
# end

# vertices = [
#   Vertex.new([3,3],"1"),
#   Vertex.new([3,5],"2"),
#   Vertex.new([5,5],"3"),
#   Vertex.new([5,3],"4"), 
# ]

# edges = [
#   Edge.new(:vertex_a=>vertices[0],:vertex_b=>vertices[1]),
#   Edge.new(:vertex_a=>vertices[1],:vertex_b=>vertices[2]),
#   Edge.new(:vertex_a=>vertices[2],:vertex_b=>vertices[3]),
#   Edge.new(:vertex_a=>vertices[3],:vertex_b=>vertices[0]),
# ]

# graph.adjacency_list.each do |current_vertex,vertex_list|
#   puts "Vertex '#{current_vertex.display_name}' (#{current_vertex.position}) is connected to:"
#   vertex_list.each do |vertex|
#     puts "     - Vertex '#{vertex.display_name}' (#{vertex.position})"
#   end 
# end


