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

inputs = {} of String => Int64 | {String, Char, String} | Nil
ARGF.each_line do |line|
  case line
  when /(\w+)\s*:\s*(\w+)\s*([-+*\/])\s*(\w+)/
    inputs[$1] = {$2, $3[0], $4}
  when /(\w+)\s*:\s*(\d+)/
    inputs[$1] = $2.to_i64
  else raise "Invalid line"
  end
end

def compute(monkey, inputs, results = {} of String => Int64?) : Int64?
  if results.has_key?(monkey)
    return results[monkey]
  end
  case input = inputs[monkey]
  when .nil? then nil
  when {String, Char, String}
    a, op, b = input.as({String, Char, String})
    aval = compute(a, inputs, results)
    bval = compute(b, inputs, results)
    if aval.nil? || bval.nil?
      results[monkey] = nil
      return nil
    end
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

def backtrack(monkey, inputs, results)
  return if monkey == "humn"
  value = results[monkey].not_nil!
  case input = inputs[monkey]
  when Int64 then return # reached number
  when Nil   then return # reached "humn"
  when {String, Char, String}
    a, op, b = input
    aval = compute(a, inputs, results)
    bval = compute(b, inputs, results)
    case {aval, bval}
    when {nil, nil} then raise "Both arguments depend on humn"
    when {nil, Int64}
      case op
      when '+' then results[a] = value - bval
      when '-' then results[a] = value + bval
      when '*' then results[a] = value // bval
      when '/' then results[a] = value * bval
      else          raise "Invalid operation: #{op}"
      end
      backtrack(a, inputs, results)
    when {Int64, nil}
      case op
      when '+' then results[b] = value - aval
      when '-' then results[b] = aval - value
      when '*' then results[b] = value // aval
      when '/' then results[b] = aval // value
      else          raise "Invalid operation: #{op}"
      end
      backtrack(b, inputs, results)
    else return # nothing to propagate anymore
    end
  end
end

score1 = compute("root", inputs)

inputs["humn"] = nil
root = inputs["root"]
raise "Value for 'root' fixed" unless root.is_a?({String, Char, String})
a, op, b = root
results = {} of String => Int64?
aval = compute(a, inputs, results)
bval = compute(b, inputs, results)

n, val = case {aval, bval}
         when {nil, _} then {a, bval}
         when {_, nil} then {b, aval}
         else               raise "Invalid backtrack?"
         end
results[n] = val
backtrack(n, inputs, results)
score2 = results["humn"]

puts "Part 1: #{score1}"
puts "Part 2: #{score2}"
