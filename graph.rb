#! /usr/bin/env ruby

class Vertex
  attr_accessor :position, :display_name

  def initialize(position_array,display_name)
    # O(1)
    raise "Invalid position" unless position_array.is_a?(Array) && position_array.length == 2 
    raise "Positions must be integers" unless position_array.first.is_a?(Integer) && position_array.last.is_a?(Integer)
    raise "Positions must be strictly positive" unless position_array.first > 0 && position_array.last > 0
    
    raise "Invalid display name" if display_name.nil?
    self.position = position_array 
    self.display_name = display_name.to_s
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

  def to_s
    self.display_name
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
    sampled_vertex_names = vertices.keys.sample($edge_frequency)

    sampled_vertex_names.each do |vertex_name|
      vertex_b = vertices[vertex_name]
      unless vertex_b == vertex_a
        # O(1)
        direction, aligned = Vertex.check_direction_and_alignment(vertex_a,vertex_b)
        # O(1)
        if aligned && board.direction_empty?(vertex_a.position,direction)
          directed = (rand < $directed_freq)
          edge_options = {
            :vertex_a=>vertex_a,:vertex_b=>vertex_b,:directed=>directed
          }
          unless $num_weights.nil?
            weight = rand($num_weights)+1 
            edge_options[:weight] = weight
          end
          new_edge = Edge.new(edge_options)
          new_edges << new_edge

          # O(1)
          board.add_line(vertex_a.position,vertex_b.position,directed,weight)
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
    self.board = options[:board] || Board.new()
    
    if !options[:vertices].nil?
      self.vertices = options[:vertices]
      self.edges = options[:edges]
      build_adjacency_list
      add_to_board
    else
      num_vertices = options[:num_vertices] || ($vertex_density)*($board_width*$board_height)
      num_vertices = num_vertices.to_i
      self.vertices = {}
      self.edges = []
      self.adjacency_list = {}

      # generate random vertices when no vertices are given
      # O(nv)
      names = (0..9).to_a + ('a'..'u').to_a+('w'..'z').to_a+('A'..'Z').to_a
      num_names = names.length

      if num_vertices > num_names
        puts "Limiting vertices number to valid names"
        num_vertices = num_names
      end

      i = 0
      num_vertices.times do 
        vertex = Vertex.generate_random_vertex(board,names[i%num_names])
        self.vertices[vertex.display_name] = vertex
        self.adjacency_list[vertex] = LinkedList.new()
        i += 1
      end

      # O(nv*ef) = O(nv)
      vertices.each do |vertex_name,vertex|
        new_edges = Edge.generate_random_edges_for_vertex(vertex,vertices,board)
       
        self.edges += new_edges
        # number of edges should be constant based on edge frequency
        new_edges.each do |edge|
          self.adjacency_list[vertex].add_to_tail(edge.vertex_b)
          unless edge.directed == true
            self.adjacency_list[edge.vertex_b].add_to_tail(vertex)
          end
        end
      end
    end
  end

  def build_adjacency_list
    # O(nv+ne)

    adj = {}
    vertices.each do |vertex_name,vertex|
      adj[vertex] = LinkedList.new()
    end

    edges.each do |edge|
      adj[edge.vertex_a].add_to_tail(edge.vertex_b)
      unless edge.directed == true
        adj[edge.vertex_b].add_to_tail(edge.vertex_a)
      end
    end

    self.adjacency_list = adj
  end

  def add_to_board
    vertices.each do |vertex_name,vertex|
      board.set_slot(vertex.position,vertex.display_name.to_s)
    end

    edges.each do |edge|
      board.add_line(edge.vertex_a,edge.vertex_b,edge.directed,edge.weight)
    end
  end

  def bfs_for_vertex(vertex)
    colors = {}
    colors[vertex] = "gray"
    nodes = {}
    root_node = nodes[vertex] = Node.new(vertex)
    bfs = Tree.new(root_node)
      
    queue = MyQueue.new()
    queue.enqueue(vertex)
    while !queue.empty?
      current_vertex = queue.dequeue
      adjacency_list[current_vertex].each do |connected_vertex|
        if colors[connected_vertex].nil?
          colors[connected_vertex] = "gray"
          nodes[connected_vertex] = bfs.add_child_to_node(nodes[current_vertex],connected_vertex)
          queue.enqueue(connected_vertex)
        end
      end
      colors[current_vertex] = "black"
    end

    return bfs
  end
end