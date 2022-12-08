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

heights = ARGF.each_line.map(&.each_char.map(&.to_i).to_a).to_a

n = heights.size
m = heights[0].size
invisible = n.times.sum do |y|
  m.times.count do |x|
    h = heights[y][x]
    inv = true
    inv &&= (x-1).downto(0).any?{|xx| heights[y][xx] >= h}
    inv &&= (x+1).upto(n-1).any?{|xx| heights[y][xx] >= h}
    inv &&= (y-1).downto(0).any?{|yy| heights[yy][x] >= h}
    inv &&= (y+1).upto(m-1).any?{|yy| heights[yy][x] >= h}
    inv
  end
end

puts "visible #{n*m - invisible}"

score = n.times.map do |y|
  m.times.map do |x|
    h = heights[y][x]
    sc = 1
    sc *= (x-1).downto(0).with_index.find{|xx| heights[y][xx[0]] >= h}.try(&.[1].+ 1) || x
    sc *= (x+1).upto(m-1).with_index.find{|xx| heights[y][xx[0]] >= h}.try(&.[1].+ 1) || (m-x-1)
    sc *= (y-1).downto(0).with_index.find{|yy| heights[yy[0]][x] >= h}.try(&.[1].+ 1) || y
    sc *= (y+1).upto(n-1).with_index.find{|yy| heights[yy[0]][x] >= h}.try(&.[1].+ 1) || (n-y-1)
    sc
  end.max
end.max

puts "score #{score}"
