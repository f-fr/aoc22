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

inputs = {} of String => Int32 | {String, Char, String}
ARGF.each_line do |line|
  case line
  when /(\w+)\s*:\s*(\w+)\s*([-+*\/])\s*(\w+)/
    inputs[$1] = {$2, $3[0], $4}
  when /(\w+)\s*:\s*(\d+)/
    inputs[$1] = $2.to_i
  else raise "Invalid line"
  end
end

enum Operator
  Add; Sub; Mul; Div
end

abstract class Expr
  abstract def eval(vars : Hash(String, Int32)) : BigRational
end

class Num < Expr
  getter num : Int32

  def initialize(@num); end

  def eval(vars : Hash(String, Int32)) : BigRational
    @num.to_big_r
  end
end

class BinOp < Expr
  getter a : Expr
  getter b : Expr
  getter op : Operator

  def initialize(@a, @op, @b); end

  def eval(vars : Hash(String, Int32)) : BigRational
    a = @a.eval(vars)
    b = @b.eval(vars)
    case @op
    in Operator::Add then a + b
    in Operator::Sub then a - b
    in Operator::Mul then a * b
    in Operator::Div then a / b
    end
  end
end

class Var < Expr
  getter name : String

  def initialize(@name); end

  def eval(vars : Hash(String, Int32)) : BigRational
    vars[@name].to_big_r
  end
end

def create_expr(inputs, name) : Expr
  if name == "humn"
    Var.new(name)
  else
    input = inputs[name]
    if input.is_a?(Int32)
      Num.new(input)
    else
      a, op, b = input
      op = case op
           when '+' then Operator::Add
           when '-' then Operator::Sub
           when '*' then Operator::Mul
           when '/' then Operator::Div
           else          raise "Invalid operator"
           end
      BinOp.new(create_expr(inputs, a), op, create_expr(inputs, b))
    end
  end
end

root = create_expr(inputs, "root").as(BinOp)
score1 = root.eval({"humn" => inputs["humn"].as(Int32)})

root = BinOp.new(root.a, Operator::Sub, root.b)
a = root.eval({"humn" => 0})
b = root.eval({"humn" => 1})
score2 = a / (a - b)

puts "Part 1: #{score1}"
puts "Part 2: #{score2}"
