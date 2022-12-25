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

def from_snafu(n)
  s = n.each_char.map do |ch|
    case ch
    when '=' then '0'
    when '-' then '1'
    when '0' then '2'
    when '1' then '3'
    when '2' then '4'
    else          raise "Invalid digit"
    end
  end.join

  s.to_i64(5) - s.size.times.reduce(0i64) { |x, _| x*5 + 2 }
end

def to_snafu(n : Int64)
  ndigit = Math.log(n, 5).ceil.to_i64 + 1
  n += ndigit.times.reduce(0i64) { |x, _| x*5 + 2 }
  digits = String.build do |b|
    while n != 0
      b << {'=', '-', '0', '1', '2'}[n % 5]
      n //= 5
    end
  end
  digits.reverse.lstrip('0')
end

score1 = to_snafu(ARGF.each_line.map { |n| from_snafu(n) }.sum)

puts "Part 1: #{score1}"
