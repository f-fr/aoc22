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

puts "--- set ---"
lines.each do |line|
  puts({4,14}.map do |k|
    i = line.each_char.cons(k).with_index.find!(&.[0].to_set.size.== k)[1]+k
    "#{k}: #{i}"
  end.join("  "))
end

puts "--- sort ---"
lines.each do |line|
  puts({4,14}.map do |k|
    i = line.each_char.cons(k).with_index.find!{|s| s[0].sort!.each.cons_pair.all?{|a,b| a < b} }[1]+k
    "#{k}: #{i}"
  end.join("  "))
end
