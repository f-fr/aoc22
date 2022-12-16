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
nodenumbers = {} of String => Int8
flows = [] of Int8

ARGF.each_line do |line|
  raise "Invalid line" unless line =~ /Valve (\w+) has flow rate=(\d+); tunnels? leads? to valves? ([[:word:], ]+)$/
  neighbors[$1] = $3.split(/\s*,\s*/)
  flow = $2.to_i8
  if $1 == "AA" || flow > 0
    nodenumbers[$1] = nodenumbers.size.to_i8
    flows << flow
  end
end

# compute all shortest paths
dists = nodenumbers.size.times.map { Array.new(nodenumbers.size, Int8::MAX) }.to_a
nodenumbers.keys.each do |u|
  q = Deque{u}
  seen = {u => 0i8}
  while v = q.shift?
    neighbors[v].each do |w|
      unless seen.has_key?(w)
        seen[w] = seen[v] + 1
        q << w
      end
    end
  end
  seen.each.select { |v, _| nodenumbers.has_key?(v) }.each { |v, d| dists[nodenumbers[u]][nodenumbers[v]] = d }
end

# the shortest distance between two "interesting" valves, used for
# computing upper bounds for pruning
min_d = dists.each.flat_map(&.each).reject(&.zero?).min

# A position of one of the persons
struct Pos
  include Comparable(Pos)

  # The node to be reached next
  getter node : Int8
  # The number of remaining steps until the is reached
  getter time : Int8

  def initialize(@node, @time); end

  def <=>(other : Pos)
    {node, time} <=> {other.node, other.time}
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

curs = { {Pos.new(nodenumbers["AA"], 4), Pos.new(nodenumbers["AA"], 4), flows} => 0 }
best = nil
TIME = 30i8
TIME.times do |i|
  puts "Minute: #{i - 3} nstates: #{curs.size}"

  nxts = {} of {Pos, Pos, Array(Int8)} => Int32
  curs.each do |cur, val|
    u1, u2, flws = cur

    # puts "state: #{cur}   value:#{val}"

    # skip states that are already too bad
    # not sure if -xi[1] is valid because we have 2 persons
    if best
      bnd = val + flws.sort_by(&.-).each.with_index.reduce(0) { |s, xi| s + xi[0].to_i32 * (TIME - i - 1 - xi[1] * min_d) }
      next if bnd < best
    end

    nxt_flws = flws
    nxt_val = val

    # compute the next possible positions for each person
    nxt1, nxt2 = {u1, u2}.map do |u|
      u, t = u.node, u.time
      if t > 0
        {Pos.new(u, t - 1)}.each
      else
        wait = 0
        if nxt_flws[u] > 0
          # reached closed u, open it
          wait = 1
          nxt_val += nxt_flws[u].to_i32 * (TIME - i - 1)
          nxt_flws = nxt_flws.dup
          nxt_flws[u] = 0
        end
        nxt_flws.each.with_index.select(&.[0].> 0).map(&.[1].to_i8).map { |v| Pos.new(v, dists[u][v] - 1 + wait) }
      end
    end.map(&.reject(&.time.+(i).>= TIME).to_a)

    best = {nxt_val, best || 0}.max

    # if there no further valves to go, just stay
    nxt1 << Pos.new(u1.node, TIME) if nxt1.empty?
    nxt2 << Pos.new(u2.node, TIME) if nxt2.empty?

    nxt1.each do |v1|
      nxt2.each do |v2|
        w1, w2 = v1, v2
        w1, w2 = w2, w1 if w1 > w2
        if nxt_val > (nxts[{w1, w2, nxt_flws}]? || -1)
          nxts[{w1, w2, nxt_flws}] = nxt_val
        end
      end
    end
  end
  curs = nxts
  # puts "---------------------"
end

puts "score 1: #{{best || 0, curs.each.map(&.[1]).max? || 0}.max}"
