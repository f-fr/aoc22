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

cur_dir = [] of String
dir_sizes = Hash(String, Int32).new(0)
ls = nil
ARGF.each_line do |line|
  case line
  when /^\$\s+cd\s+\/\s*$/ then cur_dir.clear
  when /^\$\s+cd\s+\.\.\s*$/ then cur_dir.pop
  when /^\$\s+cd\s+(\S+)\s*$/ then cur_dir.push $1
  when /^\$\s+ls\s*$/ then ls = cur_dir.join('/')
  when /^dir\s+(\S+)\s*$/ # do nothing (just a subdir)
  when /^(\d+)\s+(\S+)\s*$/ then dir_sizes.update(ls.not_nil!, &.+ $1.to_i)
  else raise "Unexpected line: #{line}"
  end
end

total_sizes = Hash(String, Int32).new(0)
dir_sizes.each do |dir, dir_size|
  path = dir.split("/", remove_empty: true)
  loop do
    total_sizes.update(path.join("/"), &.+ dir_size)
    break unless path.pop?
  end
end

puts "sum of total sizes ≤ 100000: %s" % total_sizes.each.select(&.[1].<= 100_000).map(&.[1]).sum

unused = 70_000_000 - total_sizes[""]
needed = 30_000_000 - unused
dir = total_sizes.each.select(&.[1].>= needed).min_by(&.[1])
puts "smallest directory to be freed: #{dir[0]} (total size: #{dir[1]})"
