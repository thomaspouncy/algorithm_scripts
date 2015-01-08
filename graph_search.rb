#! /usr/bin/env ruby

require "benchmark"
require 'optparse'
require './data_structures.rb'
require './graph.rb'
require './tree.rb'

# Set defaults
$board_height = 10
$board_width = 10
$vertex_density = 0.25
$edge_frequency = 8
$times_to_repeat = 1
$directed_freq = 0.25
$num_weights = nil

OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-yHEIGHT", "--height=HEIGHT", "Board height") do |h|
    $board_height = h.to_i
  end

  opts.on("-xWIDTH", "--width=WIDTH", "Board width") do |w|
    $board_width = w.to_i
  end

  opts.on("-vDENSITY", "--vertex-density=DENSITY", "Vertex density") do |vd|
    $vertex_density = vd.to_f/100
  end

  opts.on("-eEDGE", "--edge-frequency=EDGE", "Edge frequency") do |ef|
    $edge_frequency = ef.to_i
  end

  opts.on("-tTIMES", "--times=TIMES", "Times to repeat") do |t|
    $times_to_repeat = t.to_i
  end

  opts.on("-dDIRECTED", "--directed-freq=DIRECTED", "Directed frequency") do |df|
    $directed_freq = df.to_f/100
  end

  opts.on("-nWEIGHTS", "--num-weights=WEIGHTS", "Number of weights") do |nw|
    raise "This script only supports up to 7 weights (due to color limitations" if nw.to_i > 7 ||nw.to_i < 0
    $num_weights = nw.to_i
  end
end.parse!

STDOUT.sync = true

Cell = Struct.new(:value,:next)

$nil_cell = Cell.new(nil,nil)

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

  def to_s
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

  def self.colorize_by_weight(char,weight)
    return char if weight.nil?
    color_code = 30 + weight    

    return "\e[#{color_code}m#{char}\e[0m"
  end

  def colorize_by_weight(char,weight)
    self.class.colorize_by_weight(char,weight)
  end

  def add_line(start_position,end_position,directed,weight)
    end_char = colorize_by_weight('*',weight)
    undirected_chars = {
      :horizontal => colorize_by_weight('-',weight),
      :vertical => colorize_by_weight('|',weight),
      :diagonal_up => colorize_by_weight('/',weight),
      :diagonal_down => colorize_by_weight('\\',weight),
    }
    directed_chars = {
      :up=>colorize_by_weight('^',weight),
      :down=>colorize_by_weight('v',weight),
      :left=>colorize_by_weight('<',weight),
      :right=>colorize_by_weight('>',weight),
      :up_left=>colorize_by_weight("\u250f".encode('utf-8'),weight),
      :up_right=>colorize_by_weight("\u2513".encode('utf-8'),weight),
      :down_left=>colorize_by_weight("\u2517".encode('utf-8'),weight),
      :down_right=>colorize_by_weight("\u251B".encode('utf-8'),weight),
    }
    # on average O(x*y)
    return if start_position == end_position
    
    if start_position.last == end_position.last
      lower = higher = nil
      line_char = undirected_chars[:horizontal]

      if start_position.first < end_position.first 
        lower = start_position.first
        higher = end_position.first

        line_char = directed_chars[:right] if directed 

        update_position([lower,start_position.last],line_char,"right")
        update_position([higher,start_position.last],end_char,"left")
      else
        lower = end_position.first
        higher = start_position.first

        line_char = directed_chars[:left] if directed 

        update_position([lower,start_position.last],end_char,"right")
        update_position([higher,start_position.last],line_char,"left")
      end

      # O(sqrt(y^2 + x^2)) in worst case. On average, O(x*y) 
      i = lower+1
      while i < higher
        update_position([i,start_position.last],line_char,"left")
        update_position([i,start_position.last],line_char,"right")
      
        i += 1
      end
    elsif start_position.first == end_position.first
      lower = higher = nil
      line_char = undirected_chars[:vertical]

      if start_position.last < end_position.last 
        lower = start_position.last
        higher = end_position.last

        line_char = directed_chars[:down] if directed 

        update_position([start_position.first,lower],line_char,"bottom")
        update_position([start_position.first,higher],end_char,"top")
      else
        lower = end_position.last
        higher = start_position.last

        line_char = directed_chars[:up] if directed 

        update_position([start_position.first,lower],end_char,"bottom")
        update_position([start_position.first,higher],line_char,"top")
      end

      i = lower+1
      while i < higher
        update_position([start_position.first,i],line_char,"top")
        update_position([start_position.first,i],line_char,"bottom")
      
        i += 1
      end
    else
      lower = higher = nil

      line_char = ''
      if start_position.first < end_position.first
        if start_position.last < end_position.last
          if directed
            line_char = directed_chars[:down_right]
          else
            line_char = undirected_chars[:diagonal_down]
          end
        else
          if directed
            line_char = directed_chars[:up_right]
          else
            line_char = undirected_chars[:diagonal_up]
          end
        end
      else
        if start_position.last < end_position.last
          if directed
            line_char = directed_chars[:down_left]
          else
            line_char = undirected_chars[:diagonal_up]
          end
        else
          if directed
            line_char = directed_chars[:up_left]
          else
            line_char = undirected_chars[:diagonal_down]
          end
        end
      end

      if start_position.first < end_position.first
        lower = start_position
        higher = end_position

        if lower.last < higher.last
          update_position(lower,line_char,'bottomright')
          update_position(higher,end_char,'topleft')
        else
          update_position(lower,line_char,'topright')
          update_position(higher,end_char,'bottomleft')
        end
      else
        lower = end_position
        higher = start_position

        if lower.last < higher.last
          update_position(lower,end_char,'bottomright')
          update_position(higher,line_char,'topleft')
        else
          update_position(lower,end_char,'topright')
          update_position(higher,line_char,'bottomleft')
        end
      end

      if lower.last < higher.last
        i = lower.first + 1
        j = lower.last + 1
        while i < higher.first
          update_position([i,j],line_char,'topleft')
          update_position([i,j],line_char,'bottomright')

          i += 1
          j += 1
        end
      else
        i = lower.first + 1
        j = lower.last - 1
        while i < higher.first
          update_position([i,j],line_char,'topright')
          update_position([i,j],line_char,'bottomleft')

          i += 1
          j -= 1
        end

      end
    end
  end
end

graph = nil

# nv = O(y*x)
# ne = 8*nv*freq = O(y*x)
# Overall should be O(x*y)
unless $num_weights.nil?
  puts "Weights are as follows:"
  i = 1
  while i <= $num_weights
    puts Board.colorize_by_weight(i,i)
    i += 1
  end
end

$main_board = Board.new(:x_slots=>$board_width,:y_slots=>$board_height)
graph = Graph.new(:board=>$main_board)
puts $main_board
puts "Enter start vertex name:"
start_vertex_name = gets.chomp
start_vertex = graph.vertices[start_vertex_name]
raise "Invalid vertex name" if start_vertex.nil?
bfs = graph.bfs_for_vertex(start_vertex)
puts bfs
# puts "Enter end vertex name: "
# end_vertex_name = gets.chomp
# end_vertex = graph.vertices[end_vertex_name]
# raise "Invalid vertex name" if end_vertex.nil?



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


