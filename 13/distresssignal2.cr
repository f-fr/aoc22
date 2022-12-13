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

require "json"

def cmp(x, y): Int32
  case {x.as_a?, y.as_a?}
  when {Array(JSON::Any), Array(JSON::Any)}
    x, y = x.as_a, y.as_a
    x.each.zip(y.each).map{|xi, yi| cmp(xi, yi)}.find(&.!= 0) || x.size <=> y.size
  when {nil, nil} then x.as_i <=> y.as_i
  when {nil, Array(JSON::Any)} then cmp(JSON::Any.new([x]), y)
  when {Array(JSON::Any), nil} then cmp(x, JSON::Any.new([y]))
  else raise "Unsupported tokens: #{x} #{y}"
  end
end

lines = ARGF.each_line.reject(&.empty?).map {|l| JSON.parse(l)}.to_a

score1 = lines.each.slice(2).with_index.each.select { |pair, i| cmp(pair[0], pair[1]) < 0 }.map(&.[1].+ 1).sum

puts "Score 1: #{score1}"

n2 = JSON.parse("[[2]]")
n6 = JSON.parse("[[6]]")
lines << n2 << n6
lines.sort! {|a,b| cmp(a,b)}
p2 = lines.index(n2).not_nil! + 1
p6 = lines.index(n6).not_nil! + 1

puts "Score 2: #{p2 * p6}"
