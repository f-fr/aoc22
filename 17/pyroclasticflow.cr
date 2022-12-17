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
wind = ARGF.gets_to_end.strip.chars.cycle

h = 0
field = Array(Array(Bool)).new

2022.times do |i|
  stone = stones.next.as(Array({Int32, Int32}))
  pieces = stone.map { |x, y| {x + 2, y + h + 3 + 1} }
  max_h = pieces.map(&.[1]).max
  while field.size <= max_h
    field << Array.new(7, false)
  end

  # field.each.with_index.to_a.reverse.each do |row, y|
  #   puts row.each.with_index.map { |f, x|
  #     if f
  #       '#'
  #     elsif pieces.includes?({x, y})
  #       '@'
  #     else
  #       ':'
  #     end
  #   }.join
  # end
  # puts "*" * 20

  loop do
    nxt_pieces = pieces.map { |x, y| {x, y - 1} }
    break if nxt_pieces.any? { |x, y| y < 0 || field[y][x] }
    pieces = nxt_pieces

    # field.each.with_index.to_a.reverse.each do |row, y|
    #   puts row.each.with_index.map { |f, x|
    #     if f
    #       '#'
    #     elsif pieces.includes?({x, y})
    #       '@'
    #     else
    #       ':'
    #     end
    #   }.join
    # end
    # puts "-" * 20

    w = wind.next.as(Char)
    d = case w
        when '<' then -1
        when '>' then +1
        else          raise "Invalid wind"
        end

    nxt_pieces = pieces.map { |x, y| {x + d, y} }
    pieces = nxt_pieces unless nxt_pieces.any? { |x, y| x < 0 || x >= 7 || field[y][x] }

    # field.each.with_index.to_a.reverse.each do |row, y|
    #   puts row.each.with_index.map { |f, x|
    #     if f
    #       '#'
    #     elsif pieces.includes?({x, y})
    #       '@'
    #     else
    #       ':'
    #     end
    #   }.join
    # end
    # puts(w.to_s * 20)
  end

  pieces.each do |x, y|
    field[y][x] = true
    h = {h, y + 1}.max
  end

  # field.each.with_index.to_a.reverse.each do |row, y|
  #   puts row.each.with_index.map { |f, x|
  #     if f
  #       '#'
  #     elsif pieces.includes?({x, y})
  #       '@'
  #     else
  #       ':'
  #     end
  #   }.join
  # end
  # puts "height: #{h}"
  # puts "=" * 40
end

puts "Part 1: #{h}"
