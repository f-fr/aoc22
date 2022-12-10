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

sum = 0
x = 1
cycle = 1
add = nil

lines = ARGF.each_line
while (line = (add || lines.next)) != Iterator::Stop::INSTANCE
  sum += cycle * x if cycle % 40 == 20

  print (x - (cycle - 1) % 40).abs <= 1 ? "█" : " "
  puts if cycle % 40 == 0

  add = nil
  case line
  when Int then x += line
  when "noop" # do nothing
  when /addx (-?\d+)/ then add = $1.to_i
  else raise "Invalid command #{line}"
  end

  cycle += 1
end

puts "Final sum #{sum}"
