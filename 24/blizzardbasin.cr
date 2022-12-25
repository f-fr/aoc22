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

map = ARGF.each_line.map(&.chars).to_a
sizex = map[0].size - 2
sizey = map.size - 2
puts "Map size #{sizey} rows and #{sizex} columns"

blizzards = map.each.with_index.flat_map { |l, y|
  l.each.with_index.select(&.[0].in?({'<', '>', '^', 'v'})).map { |c, x| { {x, y}, [c] } }
}.to_h

# puts blizzards

class Blizzards
  @sizex : Int32
  @sizey : Int32
  @nloop : Int32
  @blizs : Array(Hash({Int32, Int32}, Set(Char)))

  def initialize(map : Array(Array(Char)))
    @sizex = map[0].size - 2
    @sizey = map.size - 2
    @nloop = @sizex.lcm(@sizey)

    b = map.each.with_index.flat_map { |l, y|
      l.each.with_index.select(&.[0].in?({'<', '>', '^', 'v'})).map { |c, x| { {x, y}, [c] } }
    }.to_h

    @blizs = @nloop.times.map do
      newb = Hash({Int32, Int32}, Set(Char)).new { |h, k| h[k] = Set(Char).new }
      b.map do |xy, cs|
        x, y = xy
        cs.each do |c|
          nx, ny = case c
                   when '<' then {x - 1, y}
                   when '>' then {x + 1, y}
                   when '^' then {x, y - 1}
                   when 'v' then {x, y + 1}
                   else          raise "Invalid char"
                   end
          newb[{(nx - 1) % @sizex + 1, (ny - 1) % @sizey + 1}] << c
        end
      end
      b = newb
    end.to_a
    @blizs.rotate!(-1)
  end

  def search(from : {Int32, Int32}, to : {Int32, Int32}, *, from_iter : Int32 = 0)
    from_iter = from_iter % @nloop
    q = Deque{ {from[0], from[1], from_iter} }
    seen = { {from[0], from[1], from_iter} => 0 }
    while u = q.shift?
      x, y, i = u
      d = seen[{x, y, i}]
      ni = (i + 1) % @blizs.size
      { {0, 0}, {-1, 0}, {1, 0}, {0, -1}, {0, 1} }.each do |dx, dy|
        nx = x + dx
        ny = y + dy
        return d + 1 if to == {nx, ny}
        if (((1 <= nx <= @sizex) && (1 <= ny <= @sizey)) || {nx, ny} == from) && !seen.has_key?({nx, ny, ni}) && !@blizs[ni].has_key?({nx, ny})
          seen[{nx, ny, ni}] = d + 1
          q << {nx, ny, ni}
        end
      end
    end

    nil
  end
end

s = {map[0].index!('.'), 0}
e = {map[-1].index!('.'), map.size - 1}

b = Blizzards.new(map)
score1 = b.search(s, e)
raise "No path found" unless score1

puts "Part 1: #{score1}"

d = b.search(e, s, from_iter: score1)
raise "No backward path found" unless d
score2 = b.search(s, e, from_iter: score1 + d).not_nil! + score1 + d
puts "Part 2: #{score2}"
