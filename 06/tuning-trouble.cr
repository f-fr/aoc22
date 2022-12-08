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

require "benchmark"

lines = ARGF.each_line.to_a

chars = ('a'..'z').join + ('A'..'Z').join + ('0'..'9').join
lines << String.build { |b| 10_000_000.times{ b << chars[rand(61)] } } + chars
lines << String.build { |b| 10_000_000.times{ |i| b << chars[i % 61] } } + chars

puts "--- sort O(n·k·log(k))---"
puts Benchmark.measure {
  lines.each do |line|
    puts({4,14,62}.compact_map do |k|
           line.each_char.cons(k).with_index.find {|s| s[0].sort!.each.cons_pair.all?{|a,b| a < b} }.try { |c| "%2d: %-6d" % {k, c[1]+k} }
         end.join("  "))
  end
}

puts "--- set O(n·k)---"
puts Benchmark.measure {
  lines.each do |line|
    puts({4,14,62}.compact_map do |k|
           line.each_char.cons(k).with_index.find(&.[0].to_set.size.== k).try { |c| "%2d: %-6d" % {k, c[1]+k} }
         end.join("  "))
  end
}

puts "--- skipping hash O(n·k) ---"
puts Benchmark.measure {
  lines.each do |line|
    puts({4,14,62}.compact_map do |k|
           i = 0
           n = line.size - k
           while i < n
             poss = {} of Char => Int32
             pos = nil
             (i...i+k).find{|j| pos = poss.put(line[j], j) { nil } }
             break unless pos
             i = pos + 1
           end
           i < n ? "%2d: %-6d" % {k, i + k} : nil
         end.join("  "))
  end
}

puts "--- counting hash O(n)---"
puts Benchmark.measure {
  lines.each do |line|
    puts({4,14,62}.compact_map do |k|
           cnts = Hash(Char, Int32).new {|h,k| h[k] = 0}
           i = line.size.times.find do |i|
             cnts.delete(line[i-k]) if i >= k && cnts.update(line[i-k], &.- 1) == 1
             cnts.update(line[i], &.+ 1)
             cnts.size == k
           end.try { |n| "%2d: %-6d" % {k, n + 1} }
         end.join("  "))
  end
}

puts "--- counting array O(n)---"
puts Benchmark.measure {
  lines.each do |line|
    puts({4,14,62}.compact_map do |k|
           cnts = Array.new(256, 0)
           nmulti = 0
           i = line.size.times.find do |i|
             nmulti -= 1 if i >= k && (cnts[line[i-k].ord] -= 1) == 1
             nmulti += 1 if (cnts[line[i].ord] += 1) == 2
             i >= k-1 && nmulti == 0
           end.try { |n| "%2d: %-6d" % {k, n + 1} }
         end.join("  "))
  end
}
