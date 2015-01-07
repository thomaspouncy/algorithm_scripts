#! /usr/bin/env ruby

require "benchmark"

valid_msa_types = [
  "recursive",
  "linear",
]

msa_types = ARGV[0]
raise "MSA types required" if msa_types.nil?
msa_types = msa_types.split(" ")
msa_types.each do |msa_type|
  raise "Invalid msa type: #{msa_type}" unless valid_msa_types.include?(msa_type)
end

num_entries = ARGV[1]
raise "Number of entries required" if num_entries.nil?
num_entries = num_entries.to_i
raise "Invalid number of entries" unless num_entries > 0

class MsaMethods
  def self.recursive_msa(arr)
    return recur_msa(arr,0,arr.length-1)
  end

  def self.recur_msa(arr,low,high)
    if low < high 
      mid = ((high + low)/2).to_i

      lowest_chain = recur_msa(arr,low,mid)
      highest_chain = recur_msa(arr,mid+1,high)
      crossing_chain = crossing_msa(arr,low,mid,high)

      if lowest_chain[:count] >= highest_chain[:count] && lowest_chain[:count] >= crossing_chain[:count]
        return lowest_chain
      elsif highest_chain[:count] >= lowest_chain[:count] && highest_chain[:count] >= crossing_chain[:count]
        return highest_chain
      else
        return crossing_chain
      end
    else
      return {
        :start_point => low,
        :end_point => high,
        :count => arr[low], 
      }
    end

    return current_highest
  end

  def self.crossing_msa(arr,low,mid,high)
    current_count = 0
    max_low_count = 0
    max_low_index = mid

    i = mid
    while i > low
      current_count += arr[i]

      if current_count > max_low_count
        max_low_count = current_count
        low_index = i
      end

      i -= 1
    end

    current_count = 0
    max_high_count = 0
    max_high_index = mid

    i = mid
    while i < high
      current_count += arr[i]

      if current_count > max_high_count
        max_high_count = current_count
        max_high_index = i
      end

      i += 1
    end

    return {
      :start_point => max_low_index,
      :end_point => max_high_index,
      :count => (max_high_count + max_low_count - arr[mid]),
    }
  end

  def self.linear_msa(arr)
    current_highest = {
      :start_point=>nil,
      :end_point=>nil,
      :count=>0,
    }
    current_chain = {
      :start_point=>0,
      :end_point=>0,
      :count=>arr[0],
    }
    i = 0
    while i < (arr.length-1)
      if current_chain[:count] < 0
        current_chain[:start_point] = i+1
        current_chain[:count] = 0
      end

      current_chain[:count] += arr[i+1]
      current_chain[:end_point] = i+1

      if current_chain[:count] > current_highest[:count]
        current_highest = current_chain.clone
      end

      i += 1
    end


    return current_highest
  end
end

puts "Generating random fluctuations"
rand_fluc = []
num_entries.times do 
  rand_fluc << (rand(40) - 20)
end
puts "Random fluctuations: #{rand_fluc}" unless num_entries > 50
msa_types.each do |msa_type|
  puts "Beginning max sub array method: #{msa_type}"
  highest_chain = nil
  puts Benchmark.measure { highest_chain = MsaMethods.send("#{msa_type}_msa".to_sym,rand_fluc.clone) }
  puts "Max sub array found"
  puts "Start point: #{highest_chain[:start_point]}, end point: #{highest_chain[:end_point]}, count: #{highest_chain[:count]}"
end