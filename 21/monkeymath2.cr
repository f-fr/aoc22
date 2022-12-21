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

require "big"

inputs = {} of String => BigRational | {String, Char, String}
ARGF.each_line do |line|
  case line
  when /(\w+)\s*:\s*(\w+)\s*([-+*\/])\s*(\w+)/
    inputs[$1] = {$2, $3[0], $4}
  when /(\w+)\s*:\s*(\d+)/
    inputs[$1] = $2.to_i64.to_big_r
  else raise "Invalid line"
  end
end

def compute(monkey, inputs, results = {} of String => BigRational) : BigRational
  results[monkey]?.try { |r| return r }
  if (input = inputs[monkey]).is_a?({String, Char, String})
    a, op, b = input
    aval = compute(a, inputs, results)
    bval = compute(b, inputs, results)
    results[monkey] = case op
                      when '+' then aval + bval
                      when '-' then aval - bval
                      when '*' then aval * bval
                      when '/' then aval.to_big_r / bval.to_big_r
                      else          raise "Invalid operation: #{op}"
                      end
  else
    results[monkey] = input
  end
end

score1 = compute("root", inputs)

# root is always a linear expression in `humn`, hence solving
#    root = left - right(humn) = 0
# ⇔     0 = a + b·humn
#
# Determine a and b by setting humn=0 and humn=1 and solve
# equation for `humn`.
#
# Note that we must use rationals because there is no guarantee that
# the '/' operations create integral (intermediate) solutions.
inputs.update("root") do |root|
  a, _, b = root.as({String, Char, String})
  {a, '-', b}
end
inputs["humn"] = 0.to_big_r
a = compute("root", inputs)
inputs["humn"] = 1.to_big_r
b = compute("root", inputs)

score2 = a / (a - b)

puts "Part 1: #{score1}"
puts "Part 2: #{score2}"
