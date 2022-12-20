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

{ {1, 1, 1}, {2, 811589153, 10} }.each do |part, factor, reps|
  indata.map! { |x| {x[0] * factor, x[1]} }
  data = indata.clone

  n = (data.size - 1).to_i64
  reps.times do |iter|
    data.size.times do |i|
      j = data.index! { |_, k| k == i }
      x = data[j][0]
      data.delete_at(j)
      data.insert((x + j) % n, {x, i})
    end
  end

  zero = data.index!(&.[0].zero?)
  score = {1000, 2000, 3000}.map { |n| data[(zero + n) % data.size][0] }.sum

  puts "Part #{part}: #{score}"
end
