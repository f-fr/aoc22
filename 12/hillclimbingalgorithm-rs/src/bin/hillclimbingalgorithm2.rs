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
use std::marker::PhantomData;

use rs_graph::adjacencies::Adjacencies;
use rs_graph::search::bfs;
use rs_graph::traits::{GraphIterator, GraphType};

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
    let start_point = start_point.ok_or("Missing start point")?;
    let end_point = end_point.ok_or("Missing start point")?;

    let adj = FnGraph::from(|u: Option<(usize, usize)>| {
        let h_u = u.map(|u| grid[u.0][u.1]).unwrap_or(0);
        let grid = &grid;
        let n = grid.len() as isize;
        let m = grid[0].len() as isize;
        if let Some(u) = u {
            let (i, j) = (u.0 as isize, u.1 as isize);
            vec![(i - 1, j), (i + 1, j), (i, j - 1), (i, j + 1)]
        } else {
            grid.iter()
                .enumerate()
                .flat_map(|(i, line)| line.iter().enumerate().filter(|(_, c)| **c == 0).map(move |(j, _)| (i as isize, j as isize)))
                .collect()
        }
        .into_iter()
        .filter(move |v| 0 <= v.0 && v.0 < n && 0 <= v.1 && v.1 < m)
        .map(|(i, j)| (i as usize, j as usize))
        .filter(move |v| grid[v.0][v.1] <= h_u + 1)
        .map(Some)
        .map(move |v| ((u, v), v))
    });

    for (i, start_point) in [Some(start_point), None].into_iter().enumerate() {
        let mut dists = vec![vec![None; grid[0].len()]; grid.len()];
        if let Some(s) = start_point {
            dists[s.0][s.1] = Some(0);
        }
        for (v, (u, _)) in bfs::start(&adj, start_point) {
            let v = v.unwrap();
            dists[v.0][v.1] = u.map(|u| dists[u.0][u.1].map(|d| d + 1)).unwrap_or(Some(0));
            if v == end_point {
                break;
            }
        }

        println!("Part {}: {}", i + 1, dists[end_point.0][end_point.1].expect("No path"));
    }

    Ok(())
}

struct FnGraph<V, E, N, NIt> {
    neighsfn: N,
    phantom: PhantomData<(V, E, NIt)>,
}

impl<'a, V, E, N, NIt> GraphType<'a> for FnGraph<V, E, N, NIt>
where
    V: Copy + Eq + 'a,
    E: Copy + Eq + 'a,
    N: Fn(V) -> NIt,
    NIt: Iterator<Item = (E, V)> + Clone,
{
    type Node = V;
    type Edge = E;
}

#[derive(Clone)]
struct FnNeighIt<NIt>
where
    NIt: Clone,
{
    it: NIt,
}

impl<V, E, N, NIt> GraphIterator<FnGraph<V, E, N, NIt>> for FnNeighIt<NIt>
where
    NIt: Iterator<Item = (E, V)> + Clone,
{
    type Item = (E, V);
    fn next(&mut self, _g: &FnGraph<V, E, N, NIt>) -> Option<Self::Item> {
        self.it.next()
    }
}

impl<'a, V, E, N, NIt: Clone> Adjacencies<'a> for FnGraph<V, E, N, NIt>
where
    V: Copy + Eq + 'a,
    E: Copy + Eq + 'a,
    N: Fn(V) -> NIt,
    NIt: Iterator<Item = (E, V)> + Clone,
{
    type IncidenceIt = FnNeighIt<NIt>;

    fn neigh_iter(&self, u: Self::Node) -> Self::IncidenceIt {
        FnNeighIt { it: (self.neighsfn)(u) }
    }
}

impl<'a, V, E, N, NIt: Clone> From<N> for FnGraph<V, E, N, NIt>
where
    V: Copy + Eq + 'a,
    E: Copy + Eq + 'a,
    N: Fn(V) -> NIt,
    NIt: Iterator<Item = (E, V)> + Clone,
{
    fn from(neighs: N) -> Self {
        make_adj(neighs)
    }
}

fn make_adj<'a, V, E, N, NIt>(neighs: N) -> FnGraph<V, E, N, NIt>
where
    V: Copy + Eq + 'a,
    E: Copy + Eq + 'a,
    N: Fn(V) -> NIt,
    NIt: Iterator<Item = (E, V)> + Clone,
{
    FnGraph {
        neighsfn: neighs,
        phantom: PhantomData,
    }
}
