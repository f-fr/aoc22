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

use rs_graph::search::bfs;
use rs_graph::traits::{GraphIterator, *};
use rs_graph::{Buildable, Builder, Net, NodeAttributes};
use rs_graph_derive::Graph;

struct NodeData {
    i: isize,
    j: isize,
    height: u32,
}

#[derive(Graph)]
struct Grid {
    graph: Net,
    #[nodeattrs(NodeData)]
    nodedata: Vec<NodeData>,
}

fn main() -> Result<(), Box<dyn Error>> {
    let filename = env::args().nth(1).ok_or("Missing filename")?;
    let f = File::open(filename).map(BufReader::new)?;

    let mut start_node = None;
    let mut end_node = None;
    let mut nodedata = vec![];
    let mut n = 0isize;
    let mut m = 0isize;
    let g = {
        let mut b = Net::new_builder();
        let mut nodes = vec![];
        for (i, line) in f.lines().enumerate() {
            for (j, c) in line?.chars().enumerate() {
                let u = b.add_node();
                let h = match c {
                    'S' => {
                        start_node = Some(u);
                        0
                    }
                    'E' => {
                        end_node = Some(u);
                        25
                    }
                    'a'..='z' => u32::from(c) - u32::from('a'),
                    _ => return Err("Invalid grid character".into()),
                };
                nodes.push(u);
                nodedata.push(NodeData {
                    i: i as isize,
                    j: j as isize,
                    height: h,
                });
                m = m.max(j as isize + 1);
            }
            n += 1;
        }

        for (uid, nd) in nodedata.iter().enumerate() {
            for (x, y) in [(nd.i - 1, nd.j), (nd.i + 1, nd.j), (nd.i, nd.j - 1), (nd.i, nd.j + 1)] {
                if 0 <= x && x < n && 0 <= y && y < m {
                    let vid = (x * m + y) as usize;
                    if nodedata[vid].height <= nd.height + 1 {
                        b.add_edge(nodes[uid], nodes[vid]);
                    }
                }
            }
        }

        b.into_graph()
    };
    let g = Grid { graph: g, nodedata };

    let start_node = start_node.ok_or("Missing start point")?;
    let end_node = end_node.ok_or("Missing start point")?;

    // reverse graph
    let mut dists = vec![None; g.num_nodes()];
    dists[g.node_id(end_node)] = Some(0);
    let mut best = None;
    for (v, e) in bfs::start(g.incoming(), end_node) {
        let d = dists[g.node_id(g.snk(e))].map(|d| d + 1).unwrap();
        dists[g.node_id(v)] = Some(d);
        if g.node(v).height == 0 {
            if best.is_none() {
                best = Some(d)
            }
            if v == start_node {
                println!("Part 1: {}", d);
                println!("Part 2: {}", best.unwrap_or(d));
                break;
            }
        }
    }

    Ok(())
}
