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

score = ARGF.each_line.each_slice(3).map do |lines|
  p = lines.map(&.chars.to_set).reduce{|a,b| a&b}.to_a[0]
  case p
  when 'a'..'z' then p - 'a' + 1
  when 'A'..'Z' then p - 'A' + 27
  else raise "Invalid character"
  end
end.sum

puts "Priorities of badges: #{score}"
