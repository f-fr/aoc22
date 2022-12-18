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
end.to_set

DIRS = { {-1, 0, 0}, {0, -1, 0}, {0, 0, -1}, {1, 0, 0}, {0, 1, 0}, {0, 0, 1} }

def count_edges(cubes)
  cubes.each.map do |x, y, z|
    DIRS.each.count do |dx, dy, dz|
      cubes.includes?({x + dx, y + dy, z + dz})
    end
  end.sum // 2
end

score1 = cubes.size * 6 - 2 * count_edges(cubes)

nx = cubes.map(&.[0]).max + 1
ny = cubes.map(&.[1]).max + 1
nz = cubes.map(&.[2]).max + 1

# bfs from outside
u = {nx, ny, nz}
seen = Set{u}
q = Deque{u}
while u = q.shift?
  x, y, z = u
  DIRS.each do |dx, dy, dz|
    v = {x + dx, y + dy, z + dz}
    next unless 0 <= v[0] <= nx
    next unless 0 <= v[1] <= ny
    next unless 0 <= v[2] <= nz
    next if cubes.includes?(v)
    next if seen.includes?(v)
    seen.add(v)
    q << v
  end
end

all_cubes = (0..nx).to_a.cartesian_product((0..ny).to_a, (0..nz).to_a).to_set
inair_cubes = all_cubes # all cubes
  .subtract(cubes)      # minus solid cubes
  .subtract(seen)       # minus air cubes reachable from outside

score2 = score1 - 6 * (inair_cubes.size) + count_edges(inair_cubes) * 2

puts "Part 1: #{score1}"
puts "Part 2: #{score2}"
