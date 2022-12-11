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

class Monkey
  property items = [] of Int64
  property operation : Int64 -> Int64 = ->(x : Int64) { x }
  property testdiv : Int64 = 1
  property ontrue : Int64 = 0
  property onfalse : Int64 = 0
end

monkeys = [] of Monkey
m = nil
ARGF.each_line do |line|
  case line
  when /^\s*$/ then next
  when /Monkey\s+(\d+)\s*:/
    raise "Unexpected monkey number" if $1.to_i != monkeys.size
    m = Monkey.new
    monkeys << m
  when /Starting items:\s*([0-9, ]+)$/
    m.not_nil!.items = $1.split(',').map(&.to_i64)
  when /Operation:\s*new\s*=\s*old\s*([+*])\s*(\d+|old)/
    y = $2.to_i64?
    op = case {$1[0]?, y}
         when {'+', nil} then ->(old : Int64) { old + old }
         when {'*', nil} then ->(old : Int64) { old * old }
         when {'+', Int64} then ->(old : Int64) { old + y }
         when {'*', Int64} then ->(old : Int64) { old * y }
         else raise "Unknown operation: #{line}"
         end
    m.not_nil!.operation = op
  when /Test:\s*divisible\s+by\s+(\d+)/
    m.not_nil!.testdiv = $1.to_i
  when /If\s+true:\s*throw\s+to\s+monkey\s+(\d+)/
    m = m.not_nil!
    m.ontrue = $1.to_i
    raise "Monkey #{monkeys.size-1} throws to itself: #{m.ontrue}" if m.ontrue == monkeys.size - 1
  when /If\s+false:\s*throw\s+to\s+monkey\s+(\d+)/
    m = m.not_nil!
    m.onfalse = $1.to_i
    raise "Monkey #{monkeys.size-1} throws to itself: #{m.onfalse}" if m.onfalse == monkeys.size - 1
  else
    raise "Invalid input line: #{line}"
  end
end

mod = monkeys.each.map(&.testdiv).product

{ {3, 20}, {1, 10000} }.each do |div, niter|
  cnts = Array.new(monkeys.size, 0)
  items = monkeys.map(&.items.dup)
  niter.times do |round|
    monkeys.each_with_index do |m, i|
      cnts[i] += items[i].size
      items[i].each do |itm|
        new = m.operation.call(itm) // div % mod
        if new % m.testdiv == 0
          items[m.ontrue] << new
        else
          items[m.onfalse] << new
        end
      end
      items[i].clear
    end
  end

  cnts.each_with_index { |cnt, i| puts "Monkey #{i} inspected items #{cnt} times" }
  score = cnts.sort[-2..-1].map(&.to_i64).product
  puts "Score: #{score}"
end
