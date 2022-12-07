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
files = Hash(Array(String), Array({String, Int32})).new { |h,k| h[k] = [] of {String, Int32} }
ls = nil
ARGF.each_line do |line|
  if line =~ /^\$\s+/
    ls = nil
    case line
    when /^\$\s+cd\s+\// then cur_dir.clear
    when /^\$\s+cd\s+\.\./ then cur_dir.pop
    when /^\$\s+cd\s+(\w+)/ then cur_dir.push $1
    when /^\$\s+ls/ then ls = cur_dir.dup
    else
      raise "Unexpected command: #{line}"
    end
  elsif ls
    case line
    when /^dir\s+(\S+)/
      # do nothing (just a subdir)
    when /^(\d+)\s+(\S+)/
      files[ls] << {$2, $1.to_i}
    else
      raise "Unexpected line: #{line}"
    end
  end
end

dir_sizes = Hash(String, Int32).new(0)
files.each do |dir, fs|
  dir_size = fs.each.map(&.[1]).sum
  d = dir.dup
  loop do
    dir_sizes[d.join("/")] += dir_size
    break if d.empty?
    d.pop
  end
end

puts "sum of total sizes ≤ 100000: %s" % dir_sizes.each.select(&.[1].<= 100_000).map(&.[1]).sum

unused = 70_000_000 - dir_sizes[""]
needed = 30_000_000 - unused
dir = dir_sizes.each.select(&.[1].>= needed).min_by(&.[1])
puts "smallest directory to be freed: #{dir[0]} (total size: #{dir[1]})"
