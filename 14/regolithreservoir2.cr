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

paths = ARGF.each_line.map do |path|
  path.split(" -> ").map(&.split(',').map(&.to_i)).map{|c| {c[0], c[1]} }
end.to_a

min_y, max_y = paths.each.flat_map(&.map(&.[1])).chain({0}.each).minmax
min_x1, max_x1 = paths.each.flat_map(&.map(&.[0])).chain({500}.each).minmax

min_x = {min_x1, 500 - (max_y - min_y) - 2}.min
max_x = {max_x1, 500 + (max_y - min_y) + 2}.max

cave = (min_y..max_y).map{Array.new(max_x - min_x + 1, '.')}
paths.each do |path|
  path.each.cons_pair.each do |from, to|
    dx, dy = to.zip(from).map{|t, f| t - f}.map(&.sign)
    x, y = from
    loop do
      cave[y - min_y][x - min_x] = '#'
      break if {x, y} == to
      x += dx
      y += dy
    end
  end
end
cave << Array.new(max_x - min_x + 1, '.')
cave << Array.new(max_x - min_x + 1, '#')

cnt_sand = 0
score1 = nil
score2 = nil
path = Array({Int32, Int32}).new(max_y - min_y + 2) # empty array with capacity
path.push({500 - min_x, 0 - min_y})
until path.empty?
  x, y = path.last
  score1 = cnt_sand if y == max_y && !score1

  if d = {0, -1, +1}.find{|d| cave[y + 1][x + d] == '.'}
    path.push({x + d, y + 1})
  else
    cnt_sand += 1
    cave[y][x] = 'o'
    path.pop
  end
end
score2 = cnt_sand

cave.each { |l| puts l.join }

puts "Part 1: #{score1}"
puts "Part 2: #{score2}"
