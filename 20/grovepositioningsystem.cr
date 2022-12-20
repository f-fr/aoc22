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
indata.map! { |x| {x[0] * 811589153, x[1]} }
positions = indata.each_with_index.map { |value, pos| {value, pos} }.to_h
data = indata.clone

def rotate(data, positions, n)
  return if n[0] == 0
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

10.times do |iter|
  puts iter
  indata.each do |n|
    rotate(data, positions, n)
    raise "Mööp" if indata.any? { |i| data[positions[i]] != i }
  end
end

zero = positions.each_key.find!(&.[0].zero?)
zero = positions[zero]
puts zero
score1 = {1000, 2000, 3000}.map do |n|
  data[(zero + n) % data.size][0]
end.sum

puts "Part 1: #{score1}"
