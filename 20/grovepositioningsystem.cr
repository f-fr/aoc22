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

indata = ARGF.each_line.map(&.to_i64).with_index.to_a

def rotate(data, positions, n)
  i = positions[n]
  dir = n[0].sign
  (n[0].abs % (data.size - 1)).abs.times do
    data[i] = data[(i + dir) % data.size]
    positions[data[i]] = i
    i = (i + dir) % data.size
  end
  data[i] = n
  positions[n] = i
end

{ {1, 1, 1}, {2, 811589153, 10} }.each do |part, factor, reps|
  indata.map! { |x| {x[0] * factor, x[1]} }
  positions = indata.each_with_index.map { |value, pos| {value, pos} }.to_h
  data = indata.clone

  reps.times do |iter|
    indata.each { |n| rotate(data, positions, n) }
  end

  zero = positions.find!(&.[0][0].zero?)[1]
  score = {1000, 2000, 3000}.map { |n| data[(zero + n) % data.size][0] }.sum

  puts "Part #{part}: #{score}"
end
