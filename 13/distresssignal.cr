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

# Compare `x[xpos...xend]` and `y[ypos...yend]`.
# Return `{result, xpos, ypos}` where `xpos` and `ypos` is the position of the first
# unparsed character in `x` and `y`.
def cmp_list(x : String, xpos : Int32, xend : Int32, y : String, ypos : Int32, yend : Int32): {Int32, Int32, Int32}
  xdone = xpos >= xend || x[xpos] == ']'
  ydone = ypos >= yend || y[ypos] == ']'
  case {xdone, ydone}
  when {true, true}  then return { 0, xpos, ypos}
  when {true, false} then return {-1, xpos, ypos}
  when {false, true} then return { 1, xpos, ypos}
  end

  loop do
    case {x[xpos], y[ypos]}
    when {'0'..'9', '0'..'9'}
      xendnum = x.index(/[],]/, xpos) || raise "Unexpected end of list"
      yendnum = y.index(/[],]/, ypos) || raise "Unexpected end of list"
      case x[xpos...xendnum].to_i <=> y[ypos...yendnum].to_i
      when -1 then return {-1, xendnum, yendnum}
      when +1 then return {+1, xendnum, yendnum}
      end
      xpos = xendnum
      ypos = yendnum
    when {'[', '['}
      c, xpos, ypos = cmp_list(x, xpos+1, xend, y, ypos+1, yend)
      return {c, xpos, ypos} if c != 0
      raise "Missing ']' at xpos:#{xpos}" if x[xpos] != ']'
      raise "Missing ']' at ypos:#{ypos}" if y[ypos] != ']'
      xpos += 1
      ypos += 1
    when {'0'..'9', '['}
      xendnum = x.index(/[],]/, xpos) || raise "Missing ']' or ','"
      c, xpos, ypos = cmp_list(x, xpos, xendnum, y, ypos+1, yend)
      return {c, xpos, ypos} if c != 0
      raise "Missing ']'" if y[ypos] != ']'
      ypos += 1
    when {'[', '0'..'9'}
      yendnum = y.index(/[],]/, ypos) || raise "Missing ']' or ','"
      c, xpos, ypos = cmp_list(x, xpos+1, xend, y, ypos, yendnum)
      return {c, xpos, ypos} if c != 0
      raise "Missing ']'" if x[xpos] != ']'
      xpos += 1
    else raise "Parse error: expect item"
    end

    xdone = xpos >= xend || x[xpos] == ']'
    ydone = ypos >= yend || y[ypos] == ']'
    case {xdone, ydone}
    when {true, true}  then return { 0, xpos, ypos}
    when {true, false} then return {-1, xpos, ypos}
    when {false, true} then return { 1, xpos, ypos}
    end

    # must be both ','
    raise "Parse error: expected ','" if xpos < xend && x[xpos] != ','
    raise "Parse error: expected ','" if ypos < yend && y[ypos] != ','
    xpos += 1
    ypos += 1
  end
end

def cmp(x, y)
  cmp_list(x, 0, x.size, y, 0, y.size)[0]
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
