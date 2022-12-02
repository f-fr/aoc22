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

total_score = ARGF.each_line.map do |line|
  opp, outcome = line.split
  opp = (opp[0]? || raise "Missing opponent") - 'A'

  case outcome
  when "X" then (opp - 1) % 3 + 1       # loose
  when "Y" then opp + 1 + 3             # draw
  else          (opp + 1) % 3 + 1 + 6   # win
  end
end.sum

puts total_score
