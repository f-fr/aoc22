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
  s, b = line.scan(/x\s*=\s*(-?\d+)\s*,\s*y\s*=\s*(-?\d+)/).map { |m| {m[1].to_i, m[2].to_i} }
  r = (s[0] - b[0]).abs + (s[1] - b[1]).abs
  {s, b, r}
end.to_a

if sensors.find { |s, _| s[1] > 100 }
  dim = 4_000_000
else
  dim = 20
end

def dist(p, q)
  (p[0] - q[0]).abs + (p[1] - q[1]).abs
end

lines = sensors.each.with_index.flat_map do |sbr, i|
  s, _, r = sbr
  {
    {+1, s[1] + r - s[0], i},
    {-1, s[1] - r + s[0], i},
    {+1, s[1] - r - s[0], i},
    {-1, s[1] + r + s[0], i},
  }.each
end.to_a

interesting_points = lines.each_combination(2)
  .select { |lines| lines[0][0] != lines[1][0] }
  .flat_map do |lines|
    l1, l2 = lines
    a, b, idx1 = l1
    c, d, idx2 = l2
    if (d - b).even?
      x = (d - b) // (a - c)
      y = a*x + b
      { {x + 1, y}, {x - 1, y}, {x, y - 1}, {x, y + 1} }
    else
      x = (d - b) // (a - c)
      y = {a*x + b, c*x + d}.min
      { {x - 1, y}, {x - 1, y + 1}, {x + 2, y}, {x + 2, y + 1}, {x, y - 1}, {x + 1, y - 1}, {x, y + 2}, {x + 1, y + 2} }
    end.each.select { |x, y| 0 <= x < dim && 0 <= y < dim }.select do |x, y|
      # only points that have distance exactly r+1 to both sensors are interesting
      {idx1, idx2}.all? { |k| dist({x, y}, sensors[k][0]) == sensors[k][2] + 1 }
    end
  end.to_a.uniq!

x, y = interesting_points.find do |x, y|
  sensors.all? { |s, _, r| (s[0] - x).abs + (s[1] - y).abs > r }
end || raise "No unique point found"

puts "x=#{x} y=#{y} score=#{4_000_000i64 * x + y}"
