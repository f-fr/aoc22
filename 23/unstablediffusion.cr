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

elves = ARGF.each_line.with_index.flat_map do |line, y|
  line.each_char.with_index.select(&.[0].== '#').map(&.[1]).map { |x| {x, y} }
end.to_set

def show(elves)
  minx, maxx = elves.map(&.[0]).minmax
  miny, maxy = elves.map(&.[1]).minmax
  puts((miny..maxy).map { |y|
    (minx..maxx).map do |x|
      if elves.includes?({x, y})
        "#"
      else
        "."
      end
    end.join
  }.join("\n"))
end

# show elves

North = 0
South = 1
West  = 2
East  = 3

score1 = 0
score2 = 0
# Phase 1
10000.times do |i|
  dir = (North + i) % 4
  elves_moves = {} of {Int32, Int32} => {Int32, Int32}
  new_fields = Hash({Int32, Int32}, Int32).new(0)
  elves.each do |x, y|
    next unless { {x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1}, {x - 1, y}, {x + 1, y}, {x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1} }.any? { |to| elves.includes?(to) }

    4.times do |off|
      d = (dir + off) % 4
      looks = case d
              when North then { {x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1} }
              when South then { {x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1} }
              when West  then { {x - 1, y - 1}, {x - 1, y}, {x - 1, y + 1} }
              when East  then { {x + 1, y - 1}, {x + 1, y}, {x + 1, y + 1} }
              else            raise "Invalid direction"
              end
      if looks.all? { |to| !elves.includes?(to) }
        elves_moves[{x, y}] = looks[1]
        new_fields[looks[1]] += 1
        break
      end
    end
  end

  # Phase 2
  moved = false
  elves = elves.map do |from|
    if (to = elves_moves[from]?) && new_fields[to] == 1
      moved = true
      to
    else
      from
    end
  end

  if !moved
    score2 = i + 1
    break
  end

  if i == 9
    minx, maxx = elves.map(&.[0]).minmax
    miny, maxy = elves.map(&.[1]).minmax
    score1 = (miny..maxy).map do |y|
      (minx..maxx).count do |x|
        !elves.includes?({x, y})
      end
    end.sum
  end

  # puts "-" * 10
  # show elves
end

puts "Part 1: #{score1}"
puts "Part 2: #{score2}"
