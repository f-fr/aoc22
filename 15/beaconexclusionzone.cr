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

sensors = ARGF.each_line.map do |line|
  s, b = line.scan(/x\s*=\s*(-?\d+)\s*,\s*y\s*=\s*(-?\d+)/).map do |m|
    {m[1].to_i, m[2].to_i}
  end
  {s, b}
end.to_a

radius = sensors.map { |s, b| {0, 1}.map { |i| s[i] - b[i] }.map(&.abs).sum }

y = 2_000_000
covered = Set({Int32, Int32}).new
sensors.zip(radius).each do |sb, r|
  s, b = sb
  h = r - (s[1] - y).abs
  if h >= 0
    ((s[0] - h)..(s[0] + h)).each { |x| covered << {x, y} }
  end
end
sensors.each(&.each { |p| covered.delete(p) })

puts "Part 1: #{covered.size}"
