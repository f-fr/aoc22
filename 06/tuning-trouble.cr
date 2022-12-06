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

lines = ARGF.each_line.to_a

puts "--- sort O(n·k·log(k))---"
lines.each do |line|
  puts({4,14}.map do |k|
    i = line.each_char.cons(k).with_index.find!{|s| s[0].sort!.each.cons_pair.all?{|a,b| a < b} }[1]+k
    "#{k}: #{i}"
  end.join("  "))
end

puts "--- set O(n·k)---"
lines.each do |line|
  puts({4,14}.map do |k|
    i = line.each_char.cons(k).with_index.find!(&.[0].to_set.size.== k)[1]+k
    "#{k}: #{i}"
  end.join("  "))
end

puts "--- counting hash O(n)---"
lines.each do |line|
  puts({4,14}.map do |k|
    cnts = Hash(Char, Int32).new {|h,k| h[k] = 0}
    i = line.size.times.find! do |i|
      cnts.delete(line[i-k]) if i >= k && (cnts[line[i-k]] -= 1) == 0
      cnts[line[i]] += 1
      cnts.size == k
    end + 1
    "#{k}: #{i}"
  end.join("  "))
end

puts "--- counting array O(n)---"
lines.each do |line|
  puts({4,14}.map do |k|
    cnts = Array.new(26, 0)
    nmulti = 0
    i = line.size.times.find! do |i|
      nmulti -= 1 if i >= k && (cnts[line[i-k] - 'a'] -= 1) == 1
      nmulti += 1 if (cnts[line[i] - 'a'] += 1) == 2
      i >= k-1 && nmulti == 0
    end + 1
    "#{k}: #{i}"
  end.join("  "))
end
