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

Scissors = {
  "A" => 1, "B" => 2, "C" => 3,
  "X" => 1, "Y" => 2, "Z" => 3,
}

total_score = ARGF.each_line.map do |line|
  opp, me = line.split
  opp = Scissors[opp] || raise "Invalid input: #{opp}"
  me = Scissors[me]? || raise "Invalid input: #{me}"

  me + case (me - opp) % 3
       when 1 then 6
       when 0 then 3
       else        0
       end
end.sum

puts total_score
