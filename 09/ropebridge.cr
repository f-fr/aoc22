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

rope = Array.new(10, {0, 0})
poss2 = Set{ rope[1] }
poss10 = Set{ rope[-1] }
ARGF.each_line.map(&.split).each do |line|
  dx, dy = case line[0]?
           when "R" then { 1,  0}
           when "L" then {-1,  0}
           when "U" then { 0,  1}
           when "D" then { 0, -1}
           else raise "Invalid step direction"
           end

  cnt = line[1]? || raise "Missing step count"
  cnt = cnt.to_i? || raise "Invalid step count #{cnt}"
  cnt.times do
    rope[0] = {rope[0][0] + dx, rope[0][1] + dy}
    (1...rope.size).each do |i|
      hx, hy = rope[i-1]
      tx, ty = rope[i]
      if (hx - tx).abs > 1 || (hy - ty).abs > 1
        tx += (hx - tx).sign
        ty += (hy - ty).sign
        rope[i] = {tx, ty}
      end

      poss2.add(rope[1])
      poss10.add(rope[-1])
    end
  end
end

puts "Number of  2-tail fields: #{poss2.size}"
puts "Number of 10-tail fields: #{poss10.size}"
