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

score1 = 0
score2 = 0
ARGF.each_line do |line|
  # with regex
  m = line.match(/(\d+)-(\d+),(\d+)-(\d+)/) || next
  a, b, x, y = {1,2,3,4}.map{|i| m[i].to_i}

  # # with split, more temporary arrays
  # m = line.split(',').map(&.split('-')).flatten.map(&.to_i)
  # a, b, x, y = {0,1,2,3}.map{|i| m[i].to_i}

  score1 += 1 if a <= x <= y <= b || x <= a <= b <= y
  score2 += 1 if a <= y && x <= b
end
puts "score1: #{score1}"
puts "score2: #{score2}"
