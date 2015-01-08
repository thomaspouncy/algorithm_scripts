#! /usr/bin/env ruby

class LinkedList
  attr_accessor :head, :tail

  def initialize()
    # O(1)
    self.head = self.tail = $nil_cell
  end

  def add_to_head(value)
    new_cell = Cell.new(value,head)
    
    self.tail = new_cell if empty?
    self.head = new_cell

    return head
  end

  def add_to_tail(value)
    # O(1)
    new_cell = Cell.new(value,$nil_cell)
    
    if empty?
      self.head = self.tail = new_cell
    else
      self.tail.next = new_cell
      self.tail = new_cell
    end

    return tail 
  end

  def remove_from_head
    # O(1)
    raise "Stack overflow" if empty?
    popped_cell = head
    self.head = popped_cell.next

    return popped_cell.value
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

  def empty?
    self.head == $nil_cell
  end
end

class MyQueue < LinkedList
  def enqueue(value)
    add_to_tail(value)
  end

  def dequeue
    remove_from_head
  end
end

class Stack < LinkedList
  def push(value)
    add_to_head(value)
  end

  def pop
    remove_from_head
  end
end
