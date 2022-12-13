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

start_point = nil
end_point = nil
grid = ARGF.each_line.with_index.map do |line, i|
  line.each_char.with_index.map do |c, j|
    case c
    when 'S'
      start_point = {i, j}
      0
    when 'E'
      end_point = {i, j}
      25
    when 'a'..'z' then (c - 'a').to_i
    else raise "Invalid input char: #{c}"
    end
  end.to_a
end.to_a

raise "Missing start point" unless start_point
s = start_point.not_nil!
raise "Missing end point" unless end_point
e = end_point.not_nil!

n = grid.size
m = grid[0].size
raise "Not a rectangular grid" unless grid.all?(&.size.== m)

2.times do |part|
  dist = grid.map(&.map{nil.as(Int32?)})
  q = Deque({Int32, Int32}).new

  if part == 0
    q << s
    dist[s[0]][s[1]] = 0
  else
    n.times do |i|
      m.times do |j|
        if grid[i][j] == 0
          q << {i, j}
          dist[i][j] = 0
        end
      end
    end
  end

  # bfs
  pred = n.times.map{Array({Int32, Int32}?).new(m, nil)}.to_a
  while u = q.shift?
    i, j = u
    break if {i, j} == e
    { {i-1, j}, {i+1, j}, {i, j-1}, {i, j+1} }.each do |v|
      y, x = v
      if 0 <= y < n && 0 <= x < m && !dist[y][x] && grid[y][x] <= grid[i][j] + 1
        pred[y][x] = u
        dist[y][x] = dist[i][j].not_nil! + 1
        q << v
      end
    end
  end

  path = n.times.map{ ['.'] * m }.to_a
  u = e
  dir = nil
  while u
    v = pred[u[0]][u[1]]
    break unless v
    dir, path[v[0]][v[1]] = case {u[0] - v[0], u[1] - v[1]}
                            when {-1, 0}
                              case dir
                              when :right then path[u[0]][u[1]] = '┌'
                              when :left  then path[u[0]][u[1]] = '┐'
                              end
                              {:up, '│'}
                            when {1, 0}
                              case dir
                              when :right then path[u[0]][u[1]] = '└'
                              when :left  then path[u[0]][u[1]] = '┘'
                              end
                              {:down, '│'}
                            when {0, -1}
                              case dir
                              when :up   then path[u[0]][u[1]] = '└'
                              when :down then path[u[0]][u[1]] = '┌'
                              end
                              {:left, '─'}
                            when {0, 1}
                              case dir
                              when :up   then path[u[0]][u[1]] = '┘'
                              when :down then path[u[0]][u[1]] = '┐'
                              end
                              {:right, '─'}
                            else raise "Invalid step"
                            end
    u = v
  end

  puts
  puts path.map(&.join).join("\n")
  puts

  puts "Part#{part+1}: #{dist[e[0]][e[1]]}"
end
