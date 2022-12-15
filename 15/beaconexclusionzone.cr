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
  r = {0, 1}.map { |i| s[i] - b[i] }.map(&.abs).sum
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

def find_intervals(sensors, y, max_x) : {Int32?, Int32, Int32}
  intervals = sensors.each.compact_map do |s, b, r|
    h = r - (s[1] - y).abs
    if h >= 0
      {Event.new(s[0] - h, -1), Event.new(s[0] + h + 1, +1)}.each
    else
      nil
    end
  end.flatten.to_a.sort!

  min_covered_x = intervals[0].time
  max_covered_x = intervals[-1].time - 1

  nopen = 0
  intervals.each do |ev|
    case ev.what
    when -1 then nopen += 1
    when  1 then nopen -= 1
    end
    if nopen == 0 && ev.time >= 0 && ev.time < max_x
      return {ev.time, min_covered_x, max_covered_x}
    end
  end
  {nil, min_covered_x, max_covered_x}
end

free_x, min_x, max_x = find_intervals(sensors, y, dim)
n_beacons_in_y = sensors.each.compact_map { |_, b, _| b[1] == y ? b[0] : nil }.to_set.size
n_covered = max_x - min_x + 1 - n_beacons_in_y - (free_x ? 1 : 0)

puts "Part 1: min_x:#{min_x}, max_x:#{max_x}, no-beacon:#{n_covered}"

struct Event
  getter time : Int32
  getter what : Int32

  def initialize(@time, @what)
  end

  def <=>(ev : Event)
    {time, what} <=> {ev.time, ev.what}
  end

  def to_s(io)
    io << (what < 0 ? "[" : "]") << time
  end
end

dim.times do |y|
  x, _, _ = find_intervals(sensors, y, dim)
  if x
    puts "Part 2: x=#{x}, y=#{y} score=#{x.to_i64 * 4_000_000i64 + y.to_i64}"
  end
end