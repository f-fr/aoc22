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

map = ARGF.each_line.take_while { |l| !l.empty? }.map(&.chars).to_a
moves = ARGF.each_line.join.scan(/\d+|[RL]/).map { |s| s[0].to_i? || s[0] }

xsize = map.each.map(&.size).max
map.each { |l| l.concat([' '] * (xsize - l.size)) }

y = 0
x = map[0].index(&.== '.') || raise "Start not found"
DIRS = { {1, 0}, {0, 1}, {-1, 0}, {0, -1} }
d = 0

puts map.map(&.join).join("|\n")
puts moves

moves.each do |move|
  puts({x, y, d})
  case move
  when Int32
    puts "move #{move}"
    move.times do
      nx = x + DIRS[d][0]
      ny = y + DIRS[d][1]
      if !(0 <= nx < map[y].size) || !(0 <= ny < map.size) || map[ny][nx] == ' '
        case d
        when 0 then nx = map[y].index!(&.!= ' ')
        when 1 then ny = (0...map.size).find! { |yy| map[yy][x] != ' ' }
        when 2 then nx = (map[y].size - 1).downto(0).find! { |xx| map[y][xx] != ' ' }
        when 3 then ny = (map.size - 1).downto(0).find! { |yy| map[yy][x] != ' ' }
        else        raise "Invalid direction"
        end
      end
      break if map[ny][nx] != '.'
      x = nx
      y = ny
    end
  when "R"
    d = (d + 1) % 4
    puts "goto #{DIRS[d]}"
  when "L"
    d = (d - 1) % 4
    puts "goto #{DIRS[d]}"
  else
    raise "Invalid move"
  end
end

score1 = 1000 * (y + 1) + 4*(x + 1) + d
puts "Part 1: #{score1}"
