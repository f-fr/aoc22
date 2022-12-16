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

neighbors = Hash(String, Array(String)).new { |h, k| h[k] = [] of String }
flows = {} of String => Int32

ARGF.each_line do |line|
  raise "Invalid line" unless line =~ /Valve (\w+) has flow rate=(\d+); tunnels? leads? to valves? ([[:word:], ]+)$/
  neighbors[$1] = $3.split(/\s*,\s*/)
  neighbors[$1] << $1
  flow = $2.to_i
  flows[$1] = flow if flow > 0
end

# compute all shortest paths
dists = {} of {String, String} => Int32
nodes = neighbors.keys
nodes.each do |u|
  q = Deque{u}
  seen = {u => 0}
  while v = q.shift?
    neighbors[v].each do |w|
      unless seen.has_key?(w)
        seen[w] = seen[v] + 1
        q << w
      end
    end
  end
  seen.each { |v, d| dists[{u, v}] = d }
end

struct Pos
  getter node : String
  getter time : Int32
  getter open : Int32? = nil

  def initialize(@node, @time, @open = nil); end

  def <=>(p)
    {node, time} <=> {p.node, p.time}
  end

  def >(p)
    {node, time} > {p.node, p.time}
  end

  def <(p)
    {node, time} < {p.node, p.time}
  end

  def to_s(io)
    io << "(" << @node << "," << @time << ")"
  end

  def inspect(io)
    io << "("
    @node.inspect(io)
    io << ","
    @time.inspect(io)
    io << ","
    @open.inspect(io) # 42014
    io << ")"
  end
end

# p dists
p dists.select(&.[0].== "AA").select { |uv, d| flows.has_key?(uv[1]) }

curs = {} of {Pos, Pos, Hash(String, Int32)} => Int32
curs[{Pos.new("AA", 4), Pos.new("AA", 4), flows}] = 0

best = nil

TIME = 30
TIME.times do |i|
  puts "Minute: #{i - 3} nstates: #{curs.size}"

  nxts = {} of {Pos, Pos, Hash(String, Int32)} => Int32
  curs.each do |cur, val|
    u1, u2, flws = cur

    # puts "state: #{cur}   value:#{val}"

    # skip states that are already too bad
    if best
      bnd = val + flws.each_value.map { |x| x * (TIME - i) }.sum
      u1.open.try { |x| bnd += x * (TIME - i) }
      u2.open.try { |x| bnd += x * (TIME - i) }
      next if bnd < best
    end

    nxt_flws = flws
    nxt_val = val
    open1 = nil
    open2 = nil
    if u1.time > 0
      nxt1 = {Pos.new(u1.node, u1.time - 1)}.each
    elsif flws.has_key?(u1.node)
      # reached closed u1, open it
      nxt1 = {Pos.new(u1.node, 0, nxt_flws[u1.node])}.each
      nxt_flws = nxt_flws.dup
      nxt_flws.delete(u1.node)
      open1 = "open1:#{u1.node}"
    else
      if x = u1.open
        nxt_val += x * (TIME - i)
        open1 = "opened1:#{u1.node} (#{x * (TIME - i)})"
      end
      nxt1 = nodes.select { |v| nxt_flws.has_key?(v) }.map { |v| Pos.new(v, dists[{u1.node, v}] - 1) }
    end

    if u2.time > 0
      nxt2 = {Pos.new(u2.node, u2.time - 1)}.each
    elsif nxt_flws.has_key?(u2.node)
      # reached closed u2, open it
      nxt2 = {Pos.new(u2.node, 0, nxt_flws[u2.node])}.each
      nxt_flws = nxt_flws.dup
      nxt_flws.delete(u2.node)
      # open2 = "open2:#{u2.node}"
    else
      if x = u2.open
        nxt_val += x * (TIME - i)
        # open2 = "opened2:#{u2.node} (#{x * (TIME - i)})"
      end
      nxt2 = nodes.select { |v| nxt_flws.has_key?(v) }.map { |v| Pos.new(v, dists[{u2.node, v}] - 1) }
    end

    best = {nxt_val, best || 0}.max

    nxt1 = nxt1.reject(&.time.+(i).> TIME).to_a
    nxt2 = nxt2.reject(&.time.+(i).> TIME).to_a
    nxt1 << Pos.new(u1.node, 0) if nxt1.empty?
    nxt2 << Pos.new(u2.node, 0) if nxt2.empty?
    # puts "  NXTS: #{nxt1} #{nxt2}"

    nxt1.each do |v1|
      nxt2.each do |v2|
        # puts "  CHECK STEP;#{u1} -> #{v1}; #{u2} -> #{v2}"
        w1, w2 = v1, v2
        w1, w2 = w2, w1 if w1 > w2
        if nxt_val > (nxts[{w1, w2, nxt_flws}]? || -1)
          # puts "  #{open1} #{open2};#{u1} -> #{v1}; #{u2} -> #{v2} (#{nxt_val})"
          nxts[{w1, w2, nxt_flws}] = nxt_val
        end
      end
    end
  end
  curs = nxts
  puts best
  # puts "---------------------"
end

# curs.each do |cur, val|
#   puts "state: #{cur}   value:#{val}"
# end
puts "score 1: #{{best || 0, curs.each.map(&.[1]).max? || 0}.max}"
