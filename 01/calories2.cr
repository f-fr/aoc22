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

top3 = [] of Int64
sum = 0
ARGF.each_line do |line|
  if line.empty?
    if top3.size < 3
      top3 << sum
      top3.sort!
    elsif sum > top3[0]
      top3[0] = sum
      top3.sort!
    end
    sum = 0
  else
    sum += line.to_i
  end
end
if sum > top3[0]
  top3[0] = sum
  top3.sort!
end

puts "max elf total: #{top3.last}"
puts "top-3 total: #{top3.sum}"
