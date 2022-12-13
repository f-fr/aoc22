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

def cmp_list(x : String, xpos : Int32, y : String, ypos : Int32): {Int32, Int32, Int32}
  raise "Parse error: expecting '['" if x[xpos] != '['
  raise "Parse error: expecting '['" if y[ypos] != '['

  xpos += 1
  ypos += 1

  case {x[xpos], y[ypos]}
  when {']', ']'} then return {0, xpos + 1, ypos + 1}
  when {']', _} then return {-1, xpos + 1, ypos + 1}
  when {_, ']'} then return {1, xpos + 1, ypos + 1}
  end

  loop do
    case {x[xpos], y[ypos]}
    when {'0'..'9', '0'..'9'}
      xend = x.index(/[],]/, xpos) || raise "Unexpected end of list"
      yend = y.index(/[],]/, ypos) || raise "Unexpected end of list"
      case x[xpos...xend].to_i <=> y[ypos...yend].to_i
      when -1 then return {-1, xend, yend}
      when +1 then return {+1, xend, yend}
      end
      xpos = xend
      ypos = yend
    when {'[', '['}
      c, xpos, ypos = cmp_list(x, xpos, y, ypos)
      return {c, xpos, ypos} if c != 0
    when {'0'..'9', '['}
      xend = x.index(/[],]/, xpos) || raise "Unexpected end of list"
      x2 = "#{x[...xpos]}[#{x[xpos...xend]}]#{x[xend..]}"
      c, xpos, ypos = cmp_list(x2, xpos, y, ypos)
      return {c, xpos, ypos} if c != 0
      xpos -= 2 # remove the two inserted characters again
    when {'[', '0'..'9'}
      yend = y.index(/[],]/, ypos) || raise "Unexpected end of list"
      y2 = "#{y[...ypos]}[#{y[ypos...yend]}]#{y[yend..]}"
      c, xpos, ypos = cmp_list(x, xpos, y2, ypos)
      return {c, xpos, ypos} if c != 0
      ypos -= 2 # remove the two inserted characters again
    else raise "Parse error: expect item"
    end

    case {x[xpos], y[ypos]}
    when {']', ']'} then return {0, xpos + 1, ypos + 1}
    when {']', _} then return {-1, xpos + 1, ypos + 1}
    when {_, ']'} then return {1, xpos + 1, ypos + 1}
    end

    # must be both ','
    xpos += 1
    ypos += 1
  end
end

def cmp(x, y)
  cmp_list(x, 0, y, 0)[0]
end

lines = ARGF.each_line.slice_after(true, &.empty?).map(&.reject(&.empty?)).to_a
score = lines.each.with_index.select{ |pair, i| cmp(pair[0], pair[1]) < 0}.map(&.[1]).sum

puts "Score: #{score}"

all_packets = lines.flatten
all_packets << "[[2]]" << "[[6]]"
all_packets.sort! {|a,b| cmp(a,b)}
p1 = all_packets.index("[[2]]").not_nil! + 1
p2 = all_packets.index("[[6]]").not_nil! + 1

puts "Score2: #{p1 * p2}"
