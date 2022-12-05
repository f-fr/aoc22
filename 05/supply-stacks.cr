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

lines = [] of String
stacks = [] of Array(Char)
ARGF.each_line(1024, chomp: true) do |line|
  if line.size == 1024
    raise "Line too long"
  elsif line.empty?
    break
  elsif line =~ /^\s*\d+(\s+\d+)*\s*$/
    stacks = line.each_char.with_index.select(&.[0].number?).map(&.[1]).map {|i|
      lines.each.compact_map(&.[i]?).select(&.letter?).to_a.reverse!
    }.to_a
  else
    lines << line
  end
end

stacks2 = stacks.clone

ARGF.each_line(1024, chomp: true) do |line|
  raise "Line too long" if line.size == 1024
  m = /^\s*move\s+(\d+)\s+from\s+(\d+)\s+to\s+(\d+)\s*$/.match(line) || raise "Invalid line"
  n = m[1].to_i
  from = m[2].to_i - 1
  to = m[3].to_i - 1

  n.times { stacks[to].push stacks[from].pop }
  stacks2[to].concat stacks2[from].pop(n)
end

puts "CrateMover 9000: #{stacks.compact_map(&.last?).join}"
puts "CrateMover 9001: #{stacks2.compact_map(&.last?).join}"
