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

cubes = ARGF.each_line.map do |line|
  x, y, z = line.split(',').map(&.to_i)
  {x, y, z}
end.to_a

# ensure all cubes are in 0...nx with one layer of air at all boundaries
minx, maxx = cubes.map(&.[0]).minmax
miny, maxy = cubes.map(&.[1]).minmax
minz, maxz = cubes.map(&.[2]).minmax
nx = maxx - minx + 3
ny = maxy - miny + 3
nz = maxz - minz + 3
cubes.map! { |x, y, z| {x - minx + 1, y - miny + 1, z - minz + 1} }

# 0 = air, 1 = seen-air (outside), 2 = lava
seen = nx.times.map { ny.times.map { Array.new(nz, 0) }.to_a }.to_a
cubes.each { |x, y, z| seen[x][y][z] = 2 }

DIRS = { {-1, 0, 0}, {0, -1, 0}, {0, 0, -1}, {1, 0, 0}, {0, 1, 0}, {0, 0, 1} }

ncovered = cubes.each.map do |x, y, z|
  DIRS.each.count do |dx, dy, dz|
    seen[x + dx][y + dy][z + dz] == 2
  end
end.sum
score1 = cubes.size * 6 - ncovered

# search from outside
u = {0, 0, 0}
q = [u]
score2 = 0
while u = q.pop?
  x, y, z = u
  DIRS.each do |dx, dy, dz|
    vx, vy, vz = x + dx, y + dy, z + dz
    next unless 0 <= vx < nx && 0 <= vy < ny && 0 <= vz < nz
    case seen[vx][vy][vz]
    when 0
      seen[vx][vy][vz] = 1
      q << {vx, vy, vz}
    when 2
      score2 += 1
    end
  end
end

puts "Part 1: #{score1}"
puts "Part 2: #{score2}"
