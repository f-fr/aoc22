/*
 * Copyright (c) 2022 Frank Fischer <frank-fischer@shadow-soft.de>
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see  <http://www.gnu.org/licenses/>
 */

use rs_graph::adjacencies::Adjacencies;
use rs_graph::search::astar;
use rs_graph::traits::GraphIterator;
use std::env;
use std::error::Error;
use std::fs::File;
use std::io::{BufRead, BufReader};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct State {
    time: usize,
    minerals: [usize; 3],
    robots: [usize; 3],
    build: Option<usize>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Edge {
    robot: usize, // which robot is build
    time: usize,  // when to robot is started to be constructed
    from: State,
}

struct StateGraph<'a> {
    blueprint: &'a [[usize; 3]],
    minutes: usize,
    max_robots: [usize; 4],
}

impl<'a> StateGraph<'a> {
    fn new(blueprint: &'a [[usize; 3]], minutes: usize) -> StateGraph {
        let mut max_robots = [usize::MAX; 4];
        for i in 0..=2 {
            max_robots[i] = (0..=3).map(|r| blueprint[r][i]).max().unwrap();
        }
        StateGraph {
            blueprint,
            minutes,
            max_robots,
        }
    }
}

#[derive(Clone)]
struct ProduceIt {
    cur: State,
    robot: usize,
}

impl<'a> GraphIterator<StateGraph<'a>> for ProduceIt {
    type Item = (Edge, State);

    fn next(&mut self, g: &StateGraph<'a>) -> Option<Self::Item> {
        if self.cur.time >= g.minutes {
            return None;
        }
        let mut nxt = State {
            time: self.cur.time + 1,
            minerals: self.cur.minerals,
            robots: self.cur.robots,
            build: None,
        };

        for i in 0..=2 {
            nxt.minerals[i] += self.cur.robots[i];
        }
        if let Some(r) = self.cur.build {
            nxt.robots[r] += 1;
        }

        loop {
            if self.robot <= 3 {
                // build robot
                if (self.robot == 3 || nxt.robots[self.robot] < g.max_robots[self.robot])
                    && (0..=2).all(|i| nxt.minerals[i] >= g.blueprint[self.robot][i])
                {
                    nxt.build = if self.robot < 3 {
                        Some(self.robot)
                    } else {
                        None
                    };
                    for i in 0..=2 {
                        nxt.minerals[i] -= g.blueprint[self.robot][i];
                    }
                    self.robot += 1;
                    return Some((
                        Edge {
                            time: self.cur.time,
                            robot: self.robot - 1,
                            from: self.cur,
                        },
                        nxt,
                    ));
                }
                self.robot += 1;
            } else if self.robot == 4 {
                nxt.build = None;
                // do not build a robot
                self.robot += 1;
                return Some((
                    Edge {
                        time: self.cur.time,
                        robot: self.robot - 1,
                        from: self.cur,
                    },
                    nxt,
                ));
            } else {
                return None;
            }
        }
    }
}

impl<'a> Adjacencies<'a> for StateGraph<'a> {
    type Node = State;
    type Edge = Edge;
    type IncidenceIt = ProduceIt;

    fn neigh_iter(&self, u: Self::Node) -> Self::IncidenceIt {
        ProduceIt { cur: u, robot: 0 }
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    let filename = env::args().nth(1).ok_or("Missing filename")?;

    let f = File::open(filename).map(BufReader::new)?;
    let mut blueprints = vec![];
    for line in f.lines() {
        let line = line?;
        let mut line = line.trim_end();
        let mut requirements = vec![];
        while let Some(i) = line.find("costs ") {
            let j = line.find('.').unwrap();
            let mut reqs = [0; 3];
            for req in line[i + 6..j].split(" and ") {
                let (amount, what) = req.split_once(' ').unwrap();
                let what = match what {
                    "ore" => 0,
                    "clay" => 1,
                    "obsidian" => 2,
                    _ => Err(format!("Unknown incredient: {what}"))?,
                };
                let amount = amount.parse::<usize>()?;
                reqs[what] = amount;
            }
            line = &line[j + 1..];
            requirements.push(reqs);
        }
        blueprints.push(requirements);
    }

    for part in 1..=2 {
        let mut score = if part == 1 { 0 } else { 1 };
        for (i, blueprint) in blueprints.iter().enumerate() {
            if part == 2 && i == 3 {
                break;
            }
            let minutes = if part == 1 { 24 } else { 32 };
            let c = minutes * minutes;
            let g = StateGraph::new(blueprint, minutes);

            let start = State {
                time: 0,
                minerals: [0, 0, 0],
                robots: [1, 0, 0],
                build: None,
            };

            // estimate remaining objective in the most stupid way
            // (each remaining timestep we get a new cracking robot)
            let bnd = |u: State| {
                let t = minutes - u.time;
                if t > 0 {
                    t * c - (t - 2) * (t - 1) / 2
                } else {
                    0
                }
            };

            let mut best = (0, start);
            for (v, _, d) in astar::start(
                &g,
                start,
                |e| {
                    if e.robot == 3 {
                        if e.time + 2 > minutes {
                            c
                        } else {
                            c - (minutes - e.time - 2)
                        }
                    } else {
                        c
                    }
                },
                bnd,
            ) {
                let obj = minutes * c - (d + bnd(v));
                if v.time == minutes {
                    if obj > best.0 {
                        best = (obj, v);
                    }
                }
                if obj <= best.0 {
                    break;
                }
            }

            println!("blueprint: {}, value: {}", i + 1, best.0);
            if part == 1 {
                score += (i + 1) * best.0;
            } else {
                score *= best.0;
            }
        }

        println!("Part {}: {}", part, score);
    }

    Ok(())
}
