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

use std::collections::HashMap;
use std::env;
use std::error::Error;
use std::fs::File;
use std::io::Read;

const N: u64 = 1_000_000_000_000;

const STONES: [[(i32, i32); 5]; 5] = [
    [(0, 0), (1, 0), (2, 0), (3, 0), (3, 0)],
    [(1, 0), (1, 2), (0, 1), (1, 1), (2, 1)],
    [(0, 0), (1, 0), (2, 0), (2, 1), (2, 2)],
    [(0, 0), (0, 1), (0, 2), (0, 3), (0, 3)],
    [(0, 0), (1, 0), (0, 1), (1, 1), (1, 1)],
];

fn main() -> Result<(), Box<dyn Error>> {
    let filename = env::args().nth(1).ok_or("Missing filename")?;

    let mut wind = String::new();
    File::open(filename)?.read_to_string(&mut wind)?;

    let mut stones = STONES.iter().enumerate().cycle();
    let mut wind = wind.trim_end().bytes().enumerate().cycle();

    let mut score1 = None;
    let mut h = 0;
    let mut hx = [0; 7];
    let mut field = vec![[false; 7]; 0];
    let mut cycle_start = None;
    let mut cycle_end = None;
    let mut cycle_heights = vec![];
    let mut seen = HashMap::new();

    for i in 0i32.. {
        let (stone_i, stone) = stones.next().unwrap();
        let mut pieces = stone.map(|(x, y)| (x + 2, y + h + 3 + 1));
        let max_h = pieces.iter().map(|(_, y)| y).max().unwrap();
        field.resize(usize::try_from(max_h + 1)?, [false; 7]);

        let mut off = None;
        loop {
            let nxt_pieces = pieces.map(|(x, y)| (x, y - 1));
            if nxt_pieces
                .iter()
                .any(|&(x, y)| y < 0 || field[y as usize][x as usize])
            {
                break;
            }
            pieces = nxt_pieces;

            let (o, w) = wind.next().unwrap();
            if off.is_none() {
                off = Some(o);
            }
            let d = match w {
                b'<' => -1,
                b'>' => 1,
                _ => Err("Invalid wind direction")?,
            };

            let nxt_pieces = pieces.map(|(x, y)| (x + d, y));
            if nxt_pieces
                .iter()
                .all(|&(x, y)| x >= 0 && x < 7 && !field[y as usize][x as usize])
            {
                pieces = nxt_pieces;
            }
        }

        for (x, y) in pieces {
            field[y as usize][x as usize] = true;
            h = h.max(y + 1);
            hx[x as usize] = hx[x as usize].max(y + 1);
        }

        if i + 1 == 2022 {
            score1 = Some(h);
        }

        cycle_heights.push(h);

        let off = off.unwrap();
        if stone_i % 5 == 0 {
            let hmap = hx.map(|t| h - t);
            if let Some(start) = seen.insert((hmap, off), i) {
                if i32::try_from(cycle_heights.len())? >= (i - start) * 5 && i + 1 >= 2022 {
                    cycle_start = Some(start);
                    cycle_end = Some(i);
                    break;
                }
            } else {
                cycle_heights.truncate(1);
            }
        }
    }

    let cycle_start = cycle_start.unwrap();
    let cycle_end = cycle_end.unwrap();
    let cycle_len = usize::try_from(cycle_end - cycle_start)?;

    println!(
        "Cycle start: after {} stones (start with stone nr: {})",
        cycle_start,
        cycle_start + 1
    );
    println!("Cycle length: {cycle_len}");

    let b = (N - u64::try_from(cycle_start)? - 1) / u64::try_from(cycle_len)?;
    let c = (N - u64::try_from(cycle_start)? - 1) % u64::try_from(cycle_len)?;

    let h_beg = cycle_heights[cycle_heights.len() - cycle_len - 1];
    let h_end = cycle_heights[cycle_heights.len() - 1];

    let score2 = b * u64::try_from(h_end - h_beg)?
        + u64::try_from(cycle_heights[cycle_heights.len() - cycle_len - 1 + usize::try_from(c)?])?;

    println!("Part 1: {}", score1.unwrap_or(0));
    println!("Part 2: {}", score2);

    Ok(())
}
