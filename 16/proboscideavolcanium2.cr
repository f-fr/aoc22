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

nodes = ARGF.each_line.map do |line|
  raise "Invalid line" unless line =~ /Valve (\w+) has flow rate=(\d+); tunnels? leads? to valves? ([[:word:], ]+)$/
  {$1, {$2.to_i, $3.split(/\s*,\s*/)}}
end.to_h

TIME = 30i8

class Tunnels
  @nodenumbers : Hash(String, Int8)
  @flows : Array(Int32)
  @dists : Array(Array(Int8))
  @middles : Hash({Int32, Int32}, Array(Int32))
  @min_d : Int8

  getter score1 : Int32? = nil
  getter score2 : Int32? = nil

  alias State = {Pos, Pos, Array(Int32)}

  def initialize(nodes : Hash(String, {Int32, Array(String)}))
    @flows = [] of Int32
    @nodenumbers = nodes.each.select do |u, flw|
      if u == "AA" || flw[0] > 0
        @flows << flw[0]
        true
      end
    end.with_index.map { |u, i| {u[0], i.to_i8} }.to_h

    n = @nodenumbers.size

    # compute all shortest paths
    @dists = n.times.map { Array.new(n, Int8::MAX) }.to_a
    @nodenumbers.each_key do |u|
      q = Deque{u}
      seen = {u => 0}
      while v = q.shift?
        nodes[v][1].each do |w|
          unless seen.has_key?(w)
            seen[w] = seen[v] + 1
            q << w
          end
        end
      end
      seen.each
        .select { |v, _| @nodenumbers.has_key?(v) }
        .each { |v, d| @dists[@nodenumbers[u]][@nodenumbers[v]] = d.to_i8 }
    end

    # the shortest distance between two "interesting" valves, used for
    # computing upper bounds for pruning
    @min_d = @dists.each.flat_map(&.each).reject(&.zero?).min

    # compute list of middle nodes of shortest paths
    @middles = Hash({Int32, Int32}, Array(Int32)).new { |h, k| h[k] = [] of Int32 }
    n.times do |u|
      n.times do |v|
        next if v == u
        n.times do |w|
          next if u == w || v == w
          @middles[{u, v}] << w if @dists[u][v] == @dists[u][w] + @dists[w][v]
        end
      end
    end
  end

  def solve
    best = 0
    @score1, @score2 = {
      {Pos.new(@nodenumbers["AA"], 0), Pos.new(@nodenumbers["AA"], TIME), @flows},
      {Pos.new(@nodenumbers["AA"], 4), Pos.new(@nodenumbers["AA"], 4), @flows},
    }.map do |start|
      best = search_solution(start, best, heur: true)
      puts "Bound: #{best}"
      best = search_solution(start, best, heur: false)
    end
  end

  # Start search
  #  - from `start` state
  #  - with best known bound `best`
  #  - use only heuristic of `heur` is `true`, otherwise use exact algorithm
  private def search_solution(start : State, best : Int32, heur : Bool)
    curs = {start => 0}
    TIME.times do |i|
      puts "Minute: #{i + 1} nstates: #{curs.size}"

      nxts = {} of State => Int32
      curs.each do |cur, val|
        u1, u2, flws = cur

        bnd = val + flws.sort_by(&.-).each.with_index.reduce(0) { |s, xi| s + xi[0].to_i32 * (TIME - i - 1 - xi[1] // 2 * (@min_d + 1)) }
        next if bnd < best

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
            nxt_flws.each.with_index.select do |vflw, v|
              next false if vflw == 0
              next false if heur && @middles[{u, v}]?.try(&.any? { |w| nxt_flws[w] > 0 })
              true
            end.map(&.[1].to_i8).map { |v| Pos.new(v, @dists[u][v] - 1 + wait) }
          end
        end.map(&.reject(&.time.+(i).>= TIME).to_a)

        best = {nxt_val, best || 0}.max

        # if there no further valves to go, just stay
        nxt1 << Pos.new(u1.node, TIME) if nxt1.empty?
        nxt2 << Pos.new(u2.node, TIME) if nxt2.empty?

        if heur
          {nxt1, nxt2}.each do |nxt|
            nxt.sort_by! { |st| -(TIME - i - 1 - st.time).to_i32 * nxt_flws[st.node] }
            nxt.truncate(0, 3)
          end
        end

        nxt1.each do |v1|
          nxt2.each do |v2|
            w1, w2 = {v1, v2}.minmax # no idea why I need this, but it does not work with v1, v2 directly
            if nxt_val > (nxts[{w1, w2, nxt_flws}]? || -1)
              nxts[{w1, w2, nxt_flws}] = nxt_val
            end
          end
        end
      end
      curs = nxts
    end
    puts "-" * 20
    best
  end
end

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
    io << ")"
  end
end

tunnels = Tunnels.new(nodes)
tunnels.solve

puts "Part 1: #{tunnels.score1}"
puts "Part 2: #{tunnels.score2}"
