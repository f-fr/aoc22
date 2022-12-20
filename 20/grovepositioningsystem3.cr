#!/usr/bin/env crystal

# Copyright (c) 2022 Frank Fischer <frank-fischer@shadow-soft.de>
#
# This program is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see  <http://www.gnu.org/licenses/>

class Node
  property num : Int64

  property left : Node? = nil
  property right : Node? = nil
  property parent : Node? = nil
  property balance : Int32 = 0
  property size : Int32 = 0

  def initialize(@num)
  end

  def reset
    @left = nil
    @right = nil
    @parent = nil
    @balance = 0
    @size = 1
  end
end

class Tree
  @root : Node? = nil

  def initialize
  end

  # Return the number of elements in this tree
  #
  # This is a O(1) operation.
  def size : Int32
    @root.try(&.size) || 0
  end

  # Return the position of `node`
  #
  # This is a O(log n) operation.
  def position(node : Node) : Int32
    u = node
    pos = u.size - (u.right.try(&.size) || 0) - 1
    while p = u.parent
      if p.right == u
        pos += (p.left.try(&.size) || 0) + 1
      end
      u = p
    end
    pos
  end

  # Append a number at the last position and return its node.
  #
  # This is a O(log n) operation.
  def append(num : Int64) : Node
    node = Node.new(num)
    insert(node, size)
    node
  end

  # Insert a node at the given position.
  #
  # This is a O(log n) operation.
  def insert(node : Node, pos : Int32)
    node.reset
    if (root = @root).nil?
      raise "Invalid position" if pos != 0
      @root = node
      return
    elsif pos == root.size # insert node at last position
      u = search(pos - 1)
      # u must not have a right child
      u.right = node
      u.balance += 1
      node.parent = u
    else
      u = search(pos)
      # find last node in left tree
      if l = u.left
        u = l
        while r = u.right
          u = r
        end
        # this node has no right child, append the node there
        u.right = node
        u.balance += 1
        node.parent = u
      else
        # no left child of u, just insert the new node there
        u.left = node
        u.balance -= 1
        node.parent = u
      end
    end

    # increase the size of u up to the root
    v = u
    while v
      v.size += 1
      v = v.parent
    end

    # rebalance tree starting at u
    rebalance(u, true)
  end

  # Remove a node from the tree
  #
  # This is a O(log n) operation.
  def remove(node : Node) : self
    if node.left && node.right
      # node has two children, find successor
      u = node.right.not_nil!
      while l = u.left
        u = l
      end

      if u == node.right
        if p = node.parent
          if node == p.left
            p.left = u
          else
            p.right = u
          end
        else
          @root = u
        end
        u.parent = node.parent

        node.left.try { |l| l.parent = u }
        u.left = node.left

        u.right.try { |r| r.parent = node }
        node.right = u.right

        node.parent = u
        u.right = node
        node.left = nil
        node.balance, u.balance = u.balance, node.balance
        node.size, u.size = u.size, node.size
      else
        # exchange node and u
        # puts "EXCH #{node.num} #{u.num}"

        n_parent = node.parent
        n_left = node.left
        n_right = node.right

        u_parent = u.parent
        u_left = u.left
        u_right = u.right

        if u_parent
          if u_parent.left == u
            u_parent.left = node
          else
            u_parent.right = node
          end
        else
          @root = node
        end
        node.parent = u_parent

        if n_parent
          if n_parent.left == node
            n_parent.left = u
          else
            n_parent.right = u
          end
        else
          @root = u
        end
        u.parent = n_parent

        n_left.parent = u if n_left
        n_right.parent = u if n_right
        u_left.parent = node if u_left
        u_right.parent = node if u_right
        u.left = n_left
        u.right = n_right
        node.left = u_left
        node.right = u_right

        node.balance, u.balance = u.balance, node.balance
        node.size, u.size = u.size, node.size
      end
    end

    u = node
    if u.left.nil?
      if p = u.parent
        if u == p.left
          p.left = u.right
          p.balance += 1
        else
          p.right = u.right
          p.balance -= 1
        end
        u.right.try { |r| r.parent = u.parent }
        u = p
      else
        @root = u.right
        return self
      end
    elsif u.right.nil?
      if p = u.parent
        if u == p.left
          p.left = u.left
          p.balance += 1
        else
          p.right = u.left
          p.balance -= 1
        end
        u.left.try { |l| l.parent = u.parent }
        u = p
      else
        @root = u.left
        return self
      end
    end

    v = u
    while v
      v.size -= 1
      v = v.parent
    end

    rebalance(u, false)

    self
  end

  # Find the node at position `pos`.
  #
  # This is a O(log n) operation.
  def find(pos : Int32) : Node
    search(pos)
  end

  # Search for node with a given position.
  private def search(pos : Int32, node : Node = @root.not_nil!) : Node
    while node
      left_size = node.left.try(&.size) || 0
      if pos == left_size
        return node
      elsif pos > left_size
        pos -= left_size + 1
        node = node.right
      else
        node = node.left
      end
    end
    raise "Node at position #{pos} not found"
  end

  # Rebalance node `x` and parent nodes.
  #
  # - `ins` should be true if rebalancing after insertion
  private def rebalance(x : Node, ins : Bool)
    while x
      if x.balance == 2
        y = x.right.not_nil!
        if y.balance >= 0 # left rotation
          if p = x.parent
            if x == p.left
              p.left = y
            else
              p.right = y
            end
          else
            @root = y
          end
          y.parent = p
          y.left.try { |l| l.parent = x }
          x.right = y.left

          y.left = x
          x.parent = y
          x.balance = 1 - y.balance
          y.balance -= 1
          y.size = x.size
          x.size = 1 + (x.left.try(&.size) || 0) + (x.right.try(&.size) || 0)
          return if ins || y.balance != 0
          x = y
        else # right-left rotation
          z = y.left.not_nil!
          if p = x.parent
            if x == p.left
              p.left = z
            else
              p.right = z
            end
          else
            @root = z
          end
          z.parent = p
          z.left.try { |l| l.parent = x }
          x.right = z.left
          z.right.try { |r| r.parent = y }
          y.left = z.right
          z.left = x
          z.right = y
          x.parent = z
          y.parent = z

          if z.balance <= 0
            x.balance = 0
          else
            x.balance = -1
          end
          if z.balance >= 0
            y.balance = 0
          else
            y.balance = 1
          end
          z.balance = 0
          z.size = x.size
          x.size = 1 + (x.left.try(&.size) || 0) + (x.right.try(&.size) || 0)
          y.size = 1 + (y.left.try(&.size) || 0) + (y.right.try(&.size) || 0)
          return if ins
          x = z
        end
      elsif x.balance == -2
        y = x.left.not_nil!
        if y.balance <= 0
          if p = x.parent
            if x == p.left
              p.left = y
            else
              p.right = y
            end
          else
            @root = y
          end
          y.parent = p
          y.right.try { |r| r.parent = x }
          x.left = y.right

          y.right = x
          x.parent = y
          x.balance = -1 - y.balance
          y.balance += 1
          y.size = x.size
          x.size = 1 + (x.left.try(&.size) || 0) + (x.right.try(&.size) || 0)
          return if ins || y.balance != 0
          x = y
        else
          z = y.right.not_nil!
          if p = x.parent
            if x == p.left
              p.left = z
            else
              p.right = z
            end
          else
            @root = z
          end
          z.parent = p
          z.left.try { |l| l.parent = y }
          y.right = z.left
          z.right.try { |r| r.parent = x }
          x.left = z.right
          z.left = y
          z.right = x
          x.parent = z
          y.parent = z

          if z.balance <= 0
            y.balance = 0
          else
            y.balance = -1
          end
          if z.balance >= 0
            x.balance = 0
          else
            x.balance = 1
          end
          z.balance = 0
          z.size = x.size
          x.size = 1 + (x.left.try(&.size) || 0) + (x.right.try(&.size) || 0)
          y.size = 1 + (y.left.try(&.size) || 0) + (y.right.try(&.size) || 0)
          return if ins
          x = z
        end
      elsif x.balance == 0
        return if ins
      elsif x.balance == -1
        return if !ins
      elsif x.balance == 1
        return if !ins
      end

      if p = x.parent
        if x == p.left
          p.balance -= ins ? 1 : -1
        else
          p.balance += ins ? 1 : -1
        end
      end
      x = p
    end
  end
end

indata = ARGF.each_line.map(&.to_i64).to_a

{ {1, 1, 1}, {2, 811589153, 10} }.each do |part, factor, reps|
  tree = Tree.new
  nodes = indata.map { |n| tree.append(n.to_i64 * factor) }

  n = (nodes.size - 1).to_i64
  reps.times do
    nodes.each do |node|
      i = tree.position(node)
      tree.remove(node)
      tree.insert(node, ((i.to_i64 + node.num).to_i64 % n).to_i32)
    end
  end

  zero = tree.position(nodes.find!(&.num.zero?))
  score = {1000, 2000, 3000}.map { |i| tree.find((zero + i) % nodes.size).num }.sum
  puts "Part #{part}: #{score}"
end
