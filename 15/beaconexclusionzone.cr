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

# Just a quick hack to set the parameters for the example and the "real" data
if sensors.find { |s, _| s[1] > 100 }
  y = 2_000_000
  dim = 4_000_000
else
  y = 10
  dim = 20
end

def find_intervals(sensors, y, dim) : {Int32?, Int32, Int32, Int32}
  # collect {pos, beg/end, growing} of the interval [beg, ..., end)
  # for each sensor
  intervals = sensors.each.compact_map do |s, b, r|
    h = r - (s[1] - y).abs
    if h >= 0
      { {s[0] - h, -1, s[1] > y}, {s[0] + h + 1, +1, s[1] > y} }.each
    else
      nil
    end
  end.flatten.to_a.sort_by! { |x, w, d|
    if w == -1            # opening
      {x, w, d ? -1 : 1}  # shrinking to the front
    else                  # closing
      {x, w, !d ? -1 : 1} # shrinking to the end
    end
  }

  min_covered_x = intervals[0][0]
  max_covered_x = intervals[-1][0] - 1

  # Line sweep on the ordered list of interval beginnings and ends
  nopen = 0
  open_x = nil
  intervals.each do |ev|
    x = ev[0]
    case ev[1]
    when -1 then nopen += 1
    when  1 then nopen -= 1
    end
    open_x = x if nopen == 0 && x >= 0 && x < dim
  end

  # estimate step size to next interesting y-coordinate
  min_step = intervals.each.cons_pair
    .select { |i, j| i[1] == -1 && j[1] == 1 } # successive [ ... )
    .select { |i, j| i[0] != i[1] }            # not [), i.e. at the same point
    .select { |i, j| 0 <= i[0] && j[0] < dim } # within bounds
    .select { |i, j| !i[2] && !j[2] }          # both must be shrinking
    .map { |i, j| (j[0] - i[0]) // 2 }         # estimate step until [ ... ) -> [)
    .min? || dim

  # estimate next interesting point for each sensor's interval
  # 1. if the sensor is below it's the y-coordinate of the sensor itself
  #    because its interval is only growing until then
  # 2. if the sensor is above then it's the point when one of the interval ends
  #    enters the feasible region (because then they will be considered in the
  #    step estimation above).
  min2 = sensors.each.map do |s, _, r|
    if s[1] > y
      s[1] - y
    else
      {s[1] + r - s[0] - y, s[1] + r - (dim - s[0]) - y}.each
    end
  end.flatten.select(&.> 0).min
  min_step = {min_step, min2}.min
  {open_x, min_covered_x, max_covered_x, {1, min_step}.max}
end

free_x, min_x, max_x, _ = find_intervals(sensors, y, dim)
n_beacons_in_y = sensors.each.compact_map { |_, b, _| b[1] == y ? b[0] : nil }.to_set.size
n_covered = max_x - min_x + 1 - n_beacons_in_y - (free_x ? 1 : 0)
puts "Part 1: min_x:#{min_x}, max_x:#{max_x}, no-beacon:#{n_covered}"

y = 0
while y < dim
  x, _, _, step = find_intervals(sensors, y, dim)
  puts "Part 2: x=#{x}, y=#{y} score=#{x.to_i64 * 4_000_000i64 + y.to_i64}" if x
  y += step
end
