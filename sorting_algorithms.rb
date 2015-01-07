#! /usr/bin/env ruby

require "benchmark"

valid_sort_types = [
  "insertion",
  "merge",
  "bubble",
  "heap",
  "quick",
  "counting",
]

sort_types = ARGV[0]
raise "Sort types required" if sort_types.nil?
sort_types = sort_types.split(" ")
sort_types.each do |sort_type|
  raise "Invalid sort types" unless valid_sort_types.include?(sort_type)
end

num_entries = ARGV[1]
raise "Number of entries required" if num_entries.nil?
num_entries = num_entries.to_i
raise "Invalid number of entries" unless num_entries > 0

class HeapDataStore
  attr_accessor :heap_size, :arr

  def initialize(arr)
    self.arr = arr
    self.heap_size = arr.length

    i = (heap_size/2).to_i - 1
    while i >= 0
      max_heapify(i)

      i -= 1
    end
  end

  def left(i)
    2*(i+1)-1
  end

  def right(i)
    2*(i+1)
  end

  def parent(i)
    ((i+1)/2).to_i - 1
  end
  
  def max_heapify(i)
    l = left(i)
    r = right(i)
    largest = i

    if l < heap_size && arr[l] > arr[largest]
      largest = l
    end
    if r < heap_size && arr[r] > arr[largest]
      largest = r
    end

    if largest != i
      exchange(i,largest)
      max_heapify(largest)
    end
  end

  def length
    self.arr.length
  end

  def exchange(i,j)
    tmp = arr[i]
    arr[i] = arr[j]
    arr[j] = tmp
  end
end

class SortMethods
  class Insertion
    def self.sort(arr)
      i = 1
      while i < arr.length
        key = arr[i]
        j = i-1
        while j >= 0 and key < arr[j]
          arr[j+1] = arr[j]
          arr[j] = key
          j -= 1
        end
        i += 1
      end

      return arr
    end
  end

  class Merge
    def self.sort(arr)
      if arr.length > 1
        low = 0
        high = arr.length
        mid = ((arr.length)/2).to_i

        low_arr = sort(arr[low..(mid-1)])
        high_arr = sort(arr[mid..(high-1)])
        sorted_arr = merge(low_arr,high_arr)
      else
        sorted_arr = arr
      end

      return sorted_arr
    end

    def self.merge(low_arr,high_arr)
      low = 0
      low_index = low
      mid = low_arr.length
      high_index = 0
      high = high_arr.length

      sorted_arr = []

      while low_index < mid || high_index < high
        if low_index == mid 
          sorted_arr << high_arr[high_index]
          high_index += 1
        elsif high_index == high
          sorted_arr << low_arr[low_index]
          low_index += 1
        elsif low_arr[low_index] < high_arr[high_index]
          sorted_arr << low_arr[low_index]
          low_index += 1
        else
          sorted_arr << high_arr[high_index]
          high_index += 1
        end
      end

      return sorted_arr
    end
  end

  class Bubble
    def self.sort(arr)
      # this is really a cocktail sort, but whatever
      direction = 1
      swapped = true
      while swapped
        swapped = false
        if direction == 1
          i = 1
        else
          i = arr.length - 1
        end
        while (direction == 1 && i < arr.length) || (direction == -1 && i > 0)
          if arr[i] < arr[i-1]
            swapped = true
            tmp = arr[i]
            arr[i] = arr[i-1]
            arr[i-1] = tmp
          end
          if direction == 1
            i += 1
          else
            i -= 1
          end
        end
        direction = direction * -1
      end

      return arr
    end
  end

  class Heap
    def self.sort(arr)
      heap = HeapDataStore.new(arr)
      while heap.heap_size > 1
        heap.exchange(0,heap.heap_size - 1)
        heap.heap_size = heap.heap_size - 1
        heap.max_heapify(0)
      end

      return heap.arr
    end
  end

  class Quick
    def self.sort(arr)
      quick_sort(arr,0,arr.length-1)
    end

    def self.quick_sort(arr,p,r)
      if p < r
        q, arr = partition(arr,p,r)
        arr = quick_sort(arr,p,q-1)
        arr = quick_sort(arr,q+1,r)
      end

      return arr 
    end

    def self.partition(arr,p,r)
      x = arr[r]

      i = p-1
      j = p
      while j < r
        if arr[j] < x
          tmp = arr[i+1]
          arr[i+1] = arr[j]
          arr[j] = tmp
          i += 1
        end

        j += 1
      end

      arr[r] = arr[i+1]
      arr[i+1] = x

      return i+1, arr
    end
  end

  class Counting
    def self.sort(arr)
      b_arr = Array.new(arr.length)
      c_hsh = {}
      k = 0

      i = 0
      while i < arr.length
        key = arr[i].to_s
        c_hsh[key] = (c_hsh[key] || 0) + 1
        k = arr[i] if arr[i] > k

        i += 1
      end

      i = 1
      while i <= k
        key1 = i.to_s
        key2 = (i-1).to_s

        c_hsh[key1] = (c_hsh[key2]||0) + (c_hsh[key1]||0)

        i += 1
      end

      i = 0
      while i < arr.length
        key = arr[i].to_s
        j = c_hsh[key] - 1
        b_arr[j] = arr[i]
        c_hsh[key] -= 1

        i += 1
      end

      return b_arr
    end
  end
end

puts "Generating unsorted list"
unsorted = []
n_factor = 1
num_entries.times do 
  unsorted << (rand(num_entries*n_factor)+1)
end
sort_types.each do |sort_type|
  puts "Beginning #{sort_type} sort"
  puts "Unsorted elements: #{unsorted}" unless num_entries > 20
  sorted = nil
  klass = Object.const_get("SortMethods::#{sort_type.split('_').collect(&:capitalize).join}")
  puts Benchmark.measure { sorted = klass.sort(unsorted.clone) }
  puts "Sort completed"
  puts "Sorted elements: #{sorted}" unless num_entries > 20
end