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

neighbors = Hash(String, Array(String)).new { |h, k| h[k] = [] of String }
flows = {} of String => Int32

ARGF.each_line do |line|
  raise "Invalid line" unless line =~ /Valve (\w+) has flow rate=(\d+); tunnels? leads? to valves? ([[:word:], ]+)$/
  neighbors[$1] = $3.split(/\s*,\s*/)
  flow = $2.to_i
  flows[$1] = flow if flow > 0
end

curs = {} of {String, Hash(String, Int32)} => Int32
curs[{"AA", flows}] = 0

30.times do |i|
  puts i
  # curs.each do |cur, val|
  #   puts "state: #{cur}   value:#{val}"
  # end
  nxts = curs.dup
  curs.each do |cur, val|
    u, flws = cur
    # just go to all neighbors
    neighbors[u].each do |v|
      if val > (nxts[{v, flws}]? || -1)
        nxts[{v, flws}] = val
      end
    end

    # maybe open u
    if flws.has_key?(u)
      # puts "Try to open #{u}"
      nxt_flws = flws.dup
      nxt_flws.delete(u)
      nxt_val = val + flws[u] * (30 - i - 1)
      if nxt_val > (nxts[{u, nxt_flws}]? || -1)
        nxts[{u, nxt_flws}] = nxt_val
      end
    end
  end
  curs = nxts
  # puts "---------------------"
end

# curs.each do |cur, val|
#   puts "state: #{cur}   value:#{val}"
# end
puts "score 1: #{curs.each.map(&.[1]).max}"
