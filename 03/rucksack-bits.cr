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

# A variant without HashSets using bitmaps
inputs = {
  # split each line in two parts
  lines.each.map { |line| line.chars.each_slice(line.size // 2).map(&.to_a).to_a }.to_a,
  # collect each 3 lines
  lines.each_slice(3).map(&.map(&.chars)).to_a
}.each_with_index do |items, i|
  score = items.map do |itms|
    bits = itms.map do |chs|
      # convert each list to a bitmap
      chs.each.map do |ch|
        case ch
        when 'a'..'z' then ch - 'a'
        when 'A'..'Z' then ch - 'A' + 26
        else raise "Invalid character"
        end
      end.map { |i| 1u64 << i }.reduce {|a,b| a | b}
    end.reduce{|a,b| a & b } # compute intersection of bitmaps

    # The score is the first non-zero bit
    s = 0
    while bits > 0
      s += 1
      bits >>= 1
    end
    s
  end.sum
  puts "score#{i+1}: #{score}"
end
