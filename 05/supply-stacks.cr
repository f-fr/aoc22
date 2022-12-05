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

stacks = [] of Array(Char)
ARGF.each_line do |line|
  break if line.empty?
  1.step(to: line.size, by: 4, exclusive: true) do |i|
    j = i//4
    case line[i]
    when 'A'..'Z'
      while stacks.size <= j
        stacks << [] of Char
      end
      stacks[j] << line[i]
    when '1'..'9'
      raise "Unexpected stack number: #{line[i].to_i}" if j+1 != line[i].to_i
    when ' '
      nil
    else
      raise "Invalid line: #{line}"
    end
  end
end

stacks.each(&.reverse!)
stacks2 = stacks.clone

ARGF.each_line do |line|
  m = /move\s+(\d+)\s+from\s+(\d+)\s+to\s+(\d+)/.match(line) || raise "Invalid line"
  n = m[1].to_i
  from = m[2].to_i - 1
  to = m[3].to_i - 1

  n.times { stacks[to].push stacks[from].pop }
  stacks2[to].concat stacks2[from].pop(n)
end

puts "CrateMover 9000: #{stacks.map(&.last).join}"
puts "CrateMover 9001: #{stacks2.map(&.last).join}"
