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
use std::io::{BufRead, BufReader, Read};

const BUFSIZE: u64 = 1024;

fn main() -> Result<(), Box<dyn Error>> {
    let filename = env::args().nth(1).ok_or("Missing filename")?;
    let mut f = File::open(filename).map(BufReader::new)?.take(BUFSIZE);

    let (mut score1, mut score2) = (0, 0);
    let mut line = String::new();
    while f.read_line(&mut line)? > 0 {
        if f.limit() == 0 {
            Err("Line too long")?;
        }
        let (ab, xy) = line.trim_end().split_once(',').ok_or("Invalid line: missing ','")?;
        let (a, b) = ab.split_once('-').ok_or("Invalid pair: missing '-'")?;
        let (x, y) = xy.split_once('-').ok_or("Invalid pair: missing '-'")?;
        let a = a.parse::<usize>().map_err(|_| "invalid number 1")?;
        let b = b.parse::<usize>().map_err(|_| "invalid number 2")?;
        let x = x.parse::<usize>().map_err(|_| "invalid number 3")?;
        let y = y.parse::<usize>().map_err(|_| "invalid number 4")?;

        if (a <= x && y <= b) || (x <= a && b <= y) {
            score1 += 1
        }
        if a <= y && x <= b {
            score2 += 1
        }

        // prepare for reading the next line of at most BUFSIZE chars
        f.set_limit(BUFSIZE);
        line.clear();
    }

    println!("score1: {}  score2:{}", score1, score2);

    Ok(())
}
