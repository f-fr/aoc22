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

ROBOTS = {"ore", "clay", "obsidian", "geode"}

blueprints = ARGF.each_line.map do |line|
  raise "Blueprint error" unless line =~ /Blueprint (\d+): (.*)$/
  bl = $1.to_i
  rbts = $2
  robots = Array({Int32, Int32, Int32}?).new(4, nil)
  rbts.scan(/Each (\w+) robot costs ([^.]+)\./) do |m|
    robot = ROBOTS.index(m[1]) || raise "Invalid robot type: #{m[1]}"
    requirements = [0, 0, 0]
    m[2].split(/\s*and\s*/).map do |what|
      raise "Invalid requirement: #{what}" unless what =~ /(\d+)\s+(\w+)/
      i = ROBOTS.index($2) || raise "Invalid requirement type: #{$2}"
      requirements[i] = $1.to_i
    end
    robots[robot] = {0, 1, 2}.map { |i| requirements[i] }
  end
  {0, 1, 2, 3}.map { |i| robots[i].not_nil! }
end.to_a

struct State
  getter minerals : {Int32, Int32, Int32}
  getter robots : {Int32, Int32, Int32}
  getter build : Int32?

  def initialize(@minerals, @robots, @build = nil); end

  def step : State
    new_minerals = {0, 1, 2}.map { |i| @minerals[i] + @robots[i] }
    new_robots = @robots.map_with_index { |r, i| i == @build ? r + 1 : r }
    State.new(new_minerals, new_robots)
  end

  def produce(req : {Int32, Int32, Int32}, robot : Int32) : State?
    if req.zip(@minerals).all? { |req, mn| req <= mn }
      new_minerals = {0, 1, 2}.map { |i| @minerals[i] - req[i] }
      State.new(new_minerals, @robots, robot < 3 ? robot : nil)
    else
      nil
    end
  end
end

def estimate_ub(state : State, time : Int32) : Int32
  # the most stupid upper bound: suppose the number of
  # geode-robots increases each time-step by 1
  val = {0, (time - 2) * (time - 1) // 2}.max
end

def greedy_ub(blueprint, state : State, time : Int32) : Int32
  value = 0
  minerals = StaticArray[state.minerals[0], state.minerals[1], state.minerals[2]]
  robots = StaticArray[state.robots[0], state.robots[1], state.robots[2]]
  build = StaticArray[false, false, false]
  time.times do |t|
    (0..2).each { |i| minerals[i] += robots[i] }
    (0..2).each { |i| robots[i] += 1 if build[i] }
    build.fill(false)
    (1..3).each do |r|
      if (1..2).all? { |i| minerals[i] >= blueprint[r][i] }
        (0..2).each { |i| minerals[i] -= blueprint[r][i] }
        if r < 3
          build[r] = true
        else
          value += time - t - 2
        end
      end
    end
  end
  value
end

{ {24, blueprints.size}, {32, 3} }.each_with_index do |params, part|
  minutes, nblueprints = params

  puts "*** PART #{part + 1} ***"
  score = part # either 0 or 1

  blueprints.first(nblueprints).each_with_index do |blueprint, bl_idx|
    print " blueprint %2d: " % {bl_idx + 1}
    print " (ub: %2d %2d)" % {greedy_ub(blueprint, State.new({0, 0, 0}, {1, 0, 0}), minutes), estimate_ub(State.new({0, 0, 0}, {1, 0, 0}), minutes)}
    best = 0
    states = {State.new({0, 0, 0}, {1, 0, 0}) => 0}
    max_robots = {0, 1, 2}.map do |i|
      i < 3 ? blueprint.map { |reqs| reqs[i] }.max : minutes
    end

    minutes.times do |minute|
      print "."
      nxt_states = {} of State => Int32
      states.each do |state, val|
        # no production
        nxt = state.step
        # next if val + estimate_ub(nxt, minutes - minute) < best
        next if val + greedy_ub(blueprint, nxt, minutes - minute) < best
        nxt_states[nxt] = val if (nxt_states[nxt]? || val - 1) < val
        # try to build each robot
        blueprint.each_with_index do |reqs, r|
          next if r < 3 && nxt.robots[r] >= max_robots[r]
          next unless nxt2 = nxt.produce(reqs, r)
          new_val = val
          new_val += (minutes - minute - 2) if r == 3 # obsidian robot -> compute cracked geodes
          best = {best, new_val}.max
          nxt_states[nxt2] = new_val if (nxt_states[nxt2]? || val - 1) < new_val
        end
      end
      states = nxt_states
    end
    puts " (#{best})"
    if part == 0
      score += (bl_idx + 1) * best
    else
      score *= best
    end
  end

  puts "Part #{part + 1}: #{score}"
end
