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

use std::env;
use std::error::Error;
use std::fs::File;
use std::io::{BufRead, BufReader};

use rs_graph::adjacencies::Adjacencies;
use rs_graph::search::bfs;
use rs_graph::traits::{GraphIterator, GraphType};

struct Grid {
    grid: Vec<Vec<u32>>,
}

type Node = Option<(usize, usize)>;
type Edge = (Node, Node);

impl<'a> GraphType<'a> for Grid {
    type Node = Node;
    type Edge = Edge;
}

#[derive(Clone)]
struct NeighIt {
    dir: usize,
    u: Node,
    start_nodes: Vec<Node>,
}

impl GraphIterator<Grid> for NeighIt {
    type Item = (Edge, Node);
    fn next(&mut self, g: &Grid) -> Option<Self::Item> {
        // add a special start node: the virtual "super-source"
        if let Some(u) = self.u {
            let mut v = None;
            while self.dir < 4 && v.is_none() {
                v = match self.dir {
                    0 if u.0 > 0 => Some((u.0 - 1, u.1)),
                    1 if u.0 + 1 < g.grid.len() => Some((u.0 + 1, u.1)),
                    2 if u.1 > 0 => Some((u.0, u.1 - 1)),
                    3 if u.1 + 1 < g.grid[u.0].len() => Some((u.0, u.1 + 1)),
                    4 => return None,
                    _ => None,
                }
                .filter(|v| g.grid[v.0][v.1] <= g.grid[u.0][u.1] + 1);
                self.dir += 1;
            }
            v.map(|v| ((Some(u), Some(v)), Some(v)))
        } else {
            if self.start_nodes.is_empty() {
                self.start_nodes = g
                    .grid
                    .iter()
                    .enumerate()
                    .flat_map(|(i, line)| line.iter().enumerate().filter(|(_, c)| **c == 0).map(move |(j, _)| Some((i, j))))
                    .collect();
            }

            if self.dir < self.start_nodes.len() {
                let v = self.start_nodes[self.dir];
                self.dir += 1;
                Some(((None, v), v))
            } else {
                None
            }
        }
    }
}

impl<'a> Adjacencies<'a> for Grid {
    type IncidenceIt = NeighIt;

    fn neigh_iter(&self, u: Self::Node) -> Self::IncidenceIt {
        NeighIt { dir: 0, u, start_nodes: vec![] }
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    let filename = env::args().nth(1).ok_or("Missing filename")?;
    let f = File::open(filename).map(BufReader::new)?;

    let mut start_point = None;
    let mut end_point = None;
    let grid = f
        .lines()
        .enumerate()
        .map(|(i, line)| {
            line?
                .chars()
                .enumerate()
                .map(|(j, c)| match c {
                    'S' => {
                        start_point = Some((i, j));
                        Ok::<_, Box<dyn Error>>(0u32)
                    }
                    'E' => {
                        end_point = Some((i, j));
                        Ok(25)
                    }
                    'a'..='z' => Ok(u32::from(c) - u32::from('a')),
                    _ => Err("Invalid grid character".into()),
                })
                .collect::<Result<Vec<_>, _>>()
        })
        .collect::<Result<Vec<_>, _>>()?;
    let grid = Grid { grid };
    let start_point = start_point.ok_or("Missing start point")?;
    let end_point = end_point.ok_or("Missing start point")?;

    println!("Part 1: {}", bfs(&grid, Some(start_point), end_point).expect("No path"));
    println!("Part 2: {}", bfs(&grid, None, end_point).expect("No path"));

    Ok(())
}

fn bfs(grid: &Grid, s: Node, end_point: (usize, usize)) -> Option<usize> {
    let mut dists = vec![vec![None; grid.grid[0].len()]; grid.grid.len()];
    if let Some(s) = s {
        dists[s.0][s.1] = Some(0);
    }
    for (v, (u, _)) in bfs::start(grid, s) {
        let v = v.unwrap();
        dists[v.0][v.1] = u.map(|u| dists[u.0][u.1].map(|d| d + 1)).unwrap_or(Some(0));
        if v == end_point {
            break;
        }
    }
    dists[end_point.0][end_point.1]
}
