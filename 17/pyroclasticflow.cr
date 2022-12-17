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

N = 1_000_000_000_000

stones = {[{0, 0}, {1, 0}, {2, 0}, {3, 0}],
          [{1, 0}, {1, 2}, {0, 1}, {1, 1}, {2, 1}],
          [{0, 0}, {1, 0}, {2, 0}, {2, 1}, {2, 2}],
          [{0, 0}, {0, 1}, {0, 2}, {0, 3}],
          [{0, 0}, {1, 0}, {0, 1}, {1, 1}]}.each.with_index.cycle
wind = ARGF.gets_to_end.strip.each_char.with_index.cycle

h = 0
hx = [0] * 7
field = Array(Array(Bool)).new

score1 = nil

cycle_start = 0
cycle_end = 0
cycle_heights = [] of Int32

alias HMap = StaticArray(Int32, 7)
# {HeightPattern, WindPosition} => SeenLastStoneNr
seen = {} of {HMap, Int32} => Int32

(0..).each do |i|
  stone, stone_i = stones.next.as({Array({Int32, Int32}), Int32})
  pieces = stone.map { |x, y| {x + 2, y + h + 3 + 1} }
  max_h = pieces.map(&.[1]).max
  while field.size <= max_h
    field << Array.new(7, false)
  end

  off = nil
  loop do
    nxt_pieces = pieces.map { |x, y| {x, y - 1} }
    break if nxt_pieces.any? { |x, y| y < 0 || field[y][x] }
    pieces = nxt_pieces

    w, o = wind.next.as({Char, Int32})
    off ||= o
    d = case w
        when '<' then -1
        when '>' then +1
        else          raise "Invalid wind"
        end

    nxt_pieces = pieces.map { |x, y| {x + d, y} }
    pieces = nxt_pieces unless nxt_pieces.any? { |x, y| x < 0 || x >= 7 || field[y][x] }
  end

  pieces.each do |x, y|
    field[y][x] = true
    h = {h, y + 1}.max
    hx[x] = {hx[x], (y + 1)}.max
  end

  score1 = h if i + 1 == 2022

  cycle_heights << h

  if stone_i % 5 == 0 && (off = off.not_nil!)
    hmap = HMap.new { |i| h - hx[i] }
    if cycle_start = seen[{hmap, off}]?
      if cycle_heights.size >= (i - cycle_start) * 5 && i + 1 >= 2022
        cycle_end = i
        break
      end
    else
      cycle_heights.truncate(0, 1)
    end
    seen[{hmap, off}] = i
  end
end

raise "Error" unless cycle_start
cycle_len = cycle_end - cycle_start

puts "Cycle start: after #{cycle_start} stones (start with stone nr: #{cycle_start + 1})"
puts "Cycle length: #{cycle_len}"

b = (N - cycle_start - 1) // cycle_len
c = (N - cycle_start - 1) % cycle_len

h_beg = cycle_heights[-cycle_len - 1]
h_end = cycle_heights[-1]

score2 = b.to_i64 * (h_end - h_beg) + cycle_heights[-cycle_len - 1 + c]

puts "Part 1: #{score1}"
puts "Part 2: #{score2}"
