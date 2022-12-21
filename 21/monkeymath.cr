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

inputs = {} of String => Int64 | {String, Char, String}
ARGF.each_line do |line|
  case line
  when /(\w+)\s*:\s*(\w+)\s*([-+*\/])\s*(\w+)/
    inputs[$1] = {$2, $3[0], $4}
  when /(\w+)\s*:\s*(\d+)/
    inputs[$1] = $2.to_i64
  else raise "Invalid line"
  end
end

def compute(monkey, inputs, results) : Int64
  if r = results[monkey]?
    return r
  end
  case input = inputs[monkey]
  when {String, Char, String}
    a, op, b = input.as({String, Char, String})
    aval = compute(a, inputs, results)
    bval = compute(b, inputs, results)
    results[monkey] = case op
                      when '+' then aval + bval
                      when '-' then aval - bval
                      when '*' then aval * bval
                      when '/' then aval // bval
                      else          raise "Invalid operation: #{op}"
                      end
  when Int64 then results[monkey] = input
  else
    raise "Something strange"
  end
end

results = {} of String => Int64
score1 = compute("root", inputs, results)
puts "Part 1: #{score1}"
