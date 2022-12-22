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

map = ARGF.each_line.take_while { |l| !l.empty? }.map(&.chars).to_a
moves = ARGF.each_line.join.scan(/\d+|[RL]/).map { |s| s[0].to_i? || s[0] }

xsize = map.each.map(&.size).max
map.each { |l| l.concat([' '] * (xsize - l.size)) }
map2 = map.map(&.clone)

y = 0
x = map[0].index(&.== '.') || raise "Start not found"
DIRS  = { {1, 0}, {0, 1}, {-1, 0}, {0, -1} }
RIGHT =  0
DOWN  =  1
LEFT  =  2
UP    =  3
N     = 50

def translate(x, y, d)
  if (N <= x < 2*N) && (y == 3*N) && (d == DOWN) # 4 down (a)
    {N - 1, 3*N + (x - N), LEFT}
  elsif (x == N) && (3*N <= y < 4*N) && (d == RIGHT) # 6 right (a)
    {N + (y - 3*N), 3*N - 1, UP}
  elsif (N <= x < 2*N) && (y == -1) && (d == UP) # 1 up (b)
    {0, 3*N + (x - N), RIGHT}
  elsif (x == -1) && (3*N <= y < 4*N) && (d == LEFT) # 6 left (b)
    {N + (y - 3*N), 0, DOWN}
  elsif (2*N <= x < 3*N) && (y == -1) && (d == UP) # 2 up (c)
    {x - 2*N, 4*N - 1, UP}
  elsif (0 <= x < N) && (y == 4*N) && (d == DOWN) # 6 down (c)
    {x + 2*N, 0, DOWN}
  elsif (x == N - 1) && (0 <= y < N) && (d == LEFT) # 1 left (d)
    {0, 3*N - 1 - y, RIGHT}
  elsif (x == -1) && (2*N <= y < 3*N) && (d == LEFT) # 5 left (d)
    {N, N - 1 - (y - 2*N), RIGHT}
  elsif (x == N - 1) && (N <= y < 2*N) && (d == LEFT) # 3 left (e)
    {y - N, 2*N, DOWN}
  elsif (0 <= x < N) && (y == 2*N - 1) && (d == UP) # 5 up (e)
    {N, N + x, RIGHT}
  elsif (x == 3*N) && (0 <= y < N) && (d == RIGHT) # 2 right (f)
    {2*N - 1, 3*N - 1 - y, LEFT}
  elsif (x == 2*N) && (2*N <= y < 3*N) && (d == RIGHT) # 4 right (f)
    {3*N - 1, N - 1 - (y - 2*N), LEFT}
  elsif (2*N <= x < 3*N) && (y == N) && (d == DOWN) # 2 down (g)
    {2*N - 1, N + (x - 2*N), LEFT}
  elsif (x == 2*N) && (N <= y < 2*N) && (d == RIGHT) # 3 right (g)
    {2*N + (y - N), N - 1, UP}
  else
    {x, y, d}
  end
end

d = RIGHT
moves.each_with_index do |move, s|
  case move
  when Int32
    move.times do
      nx = x + DIRS[d][0]
      ny = y + DIRS[d][1]
      nx, ny, nd = translate(nx, ny, d)
      raise "Mööp" if map[ny][nx] == ' '
      break if map[ny][nx] != '.'
      x = nx
      y = ny
      d = nd
      map2[y][x] = case d
                   when LEFT  then '<'
                   when RIGHT then '>'
                   when UP    then '^'
                   when DOWN  then 'v'
                   else            raise "Invalid direction"
                   end
    end
  when "R"
    d = (d + 1) % 4
  when "L"
    d = (d - 1) % 4
  else
    raise "Invalid move"
  end
  map2[y][x] = case d
               when LEFT  then '<'
               when RIGHT then '>'
               when UP    then '^'
               when DOWN  then 'v'
               else            raise "Invalid direction"
               end
end

score1 = 1000 * (y + 1) + 4*(x + 1) + d
puts "Part 2: #{score1}"
