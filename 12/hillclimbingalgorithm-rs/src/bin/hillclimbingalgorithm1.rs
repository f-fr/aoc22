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

use std::collections::VecDeque;
use std::env;
use std::error::Error;
use std::fs::File;
use std::io::{BufRead, BufReader};

fn main() -> Result<(), Box<dyn Error>> {
    let filename = env::args().nth(1).ok_or("Missing filename")?;
    let f = File::open(filename).map(BufReader::new)?;

    let mut start_point = None;
    let mut end_point = None;
    let mut grid = f
        .lines()
        .enumerate()
        .map(|(i, line)| {
            [Ok(42)]
                .into_iter()
                .chain(line?.chars().enumerate().map(|(j, c)| match c {
                    'S' => {
                        start_point = Some((i + 1, j + 1));
                        Ok::<_, Box<dyn Error>>(0u32)
                    }
                    'E' => {
                        end_point = Some((i + 1, j + 1));
                        Ok(25)
                    }
                    'a'..='z' => Ok(u32::from(c) - u32::from('a')),
                    _ => Err("Invalid grid character".into()),
                }))
                .chain([Ok(42)])
                .collect::<Result<Vec<_>, _>>()
        })
        .collect::<Result<Vec<_>, _>>()?;
    // add impassable boundary around area
    grid.insert(0, vec![42; grid[0].len()]);
    grid.push(vec![42; grid[0].len()]);

    let start_point = start_point.ok_or("Missing start point")?;
    let end_point = end_point.ok_or("Missing start point")?;

    let low_points = grid
        .iter()
        .enumerate()
        .flat_map(|(i, line)| line.iter().enumerate().filter(|(_, c)| **c == 0).map(move |(j, _)| (i, j)));

    println!("Part 1: {}", bfs(&grid, [start_point], end_point).expect("No path"));
    println!("Part 2: {}", bfs(&grid, low_points, end_point).expect("No path"));

    Ok(())
}

fn bfs<I>(grid: &[Vec<u32>], start_points: I, end_point: (usize, usize)) -> Option<usize>
where
    I: IntoIterator<Item = (usize, usize)>,
{
    let mut q = VecDeque::new();
    let mut dist = vec![vec![None; grid[0].len()]; grid.len()];
    start_points.into_iter().for_each(|s| {
        dist[s.0][s.1] = Some(0);
        q.push_back(s);
    });

    while let Some(u) = q.pop_front() {
        if u == end_point {
            break;
        }
        let h_u = grid[u.0][u.1];
        for v in [(u.0 - 1, u.1), (u.0 + 1, u.1), (u.0, u.1 - 1), (u.0, u.1 + 1)] {
            if dist[v.0][v.1].is_none() && grid[v.0][v.1] <= h_u + 1 {
                dist[v.0][v.1] = dist[u.0][u.1].map(|d| d + 1);
                q.push_back(v);
            }
        }
    }

    dist[end_point.0][end_point.1]
}
