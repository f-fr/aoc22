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

stones = {[{0, 0}, {1, 0}, {2, 0}, {3, 0}],
          [{1, 0}, {1, 2}, {0, 1}, {1, 1}, {2, 1}],
          [{0, 0}, {1, 0}, {2, 0}, {2, 1}, {2, 2}],
          [{0, 0}, {0, 1}, {0, 2}, {0, 3}],
          [{0, 0}, {1, 0}, {0, 1}, {1, 1}]}.each.cycle
windary = ARGF.gets_to_end.strip.chars.to_a
nw = windary.size.to_i64
if nw < 2022
  nw *= (2022 // nw + 1)
end
nperiod = nw * 5

NIter = 1_000_000_000_000

score1 = nil
score2 = nil

h = 0i64

wind = windary.each.cycle
hx = Array(Int64).new(7, 0i64)
field = Array(Array(Bool)).new

m = NIter - 1 * nperiod
puts(m % (7*nperiod))

j = 0
hs = 8.times.map do |k|
  puts k

  nperiod.times do |i|
    stone = stones.next.as(Array({Int32, Int32}))
    pieces = stone.map { |x, y| {x + 2, y + h + 3 + 1} }
    max_h = pieces.map(&.[1]).max
    while field.size <= max_h
      field << Array.new(7, false)
    end

    loop do
      nxt_pieces = pieces.map { |x, y| {x, y - 1} }
      break if nxt_pieces.any? { |x, y| y < 0 || field[y][x] }
      pieces = nxt_pieces

      w = wind.next.as(Char)
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
      hx[x] = {hx[x], y.to_i64 + 1}.max
    end

    score1 = h if i + 1 == 2022
    score2 = h if m % (7*nperiod) + 1 * nperiod == j + 1
    j += 1
  end

  puts "height after #{nperiod}: #{h}"

  puts(hx.map { |t| h - t })
  h
end.to_a

puts hs

score2 = (m // (7*nperiod)) * (hs[-1] - hs[0]) + hs[0] + (score2.not_nil! - hs[0])

# puts n
# puts(NIter // n)

# puts "k: #{k}"
# # puts "Part 1: #{score1}"
puts "Part 2: #{score2}"
