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
use std::io::{BufRead, BufReader, Read, Take};

use lazy_static::lazy_static;
use regex::Regex;

// Read a line of at most 1023 characters.
//
// Returns an error if the line is longer.
fn read_line<R: BufRead>(r: &mut Take<R>, line: &mut String) -> Result<bool, Box<dyn Error>> {
    line.clear();
    r.set_limit(1024);
    if r.read_line(line)? == 0 {
        Ok(false)
    } else if r.limit() == 0 {
        Err("Line too long")?
    } else {
        Ok(true)
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    let filename = env::args().nth(1).ok_or("Missing filename")?;
    let mut f = File::open(filename).map(BufReader::new)?.take(1024);
    let mut line = String::new();
    let mut lines: Vec<Vec<char>> = vec![];

    // read crate lines
    while read_line(&mut f, &mut line)? {
        if line.chars().any(|c| c.is_ascii_digit()) {
            break;
        }
        lines.push(line.chars().collect());
    }

    // collect crates per stack
    let mut stacks: Vec<Vec<_>> = line
        .chars()
        .enumerate()
        .filter(|&(_, c)| c.is_ascii_digit())
        .map(|(i, _)| lines.iter().rev().filter_map(|l| l.get(i)).filter(|c| c.is_alphabetic()).cloned().collect())
        .collect();

    let mut stacks2 = stacks.clone();

    while read_line(&mut f, &mut line)? {
        let line = line.trim_end();
        if line.is_empty() {
            continue;
        }

        lazy_static! {
            static ref RE: Regex = Regex::new(r"^\s*move\s+(\d+)\s+from\s+(\d+)\s+to\s+(\d+)\s*$").unwrap();
        }

        let caps = RE.captures(&line).ok_or("Invalid move line")?;

        let n = caps[1].parse::<usize>()?;
        let from = caps[2].parse::<usize>()?;
        let to = caps[3].parse::<usize>()?;

        if from < 1 || from > stacks.len() {
            Err("Invalid from stack number")?;
        }
        if to < 1 || to > stacks.len() {
            Err("Invalid to stack number")?;
        }

        let from = from - 1;
        let to = to - 1;

        for _ in 0..n {
            let x = stacks[from].pop().ok_or("Empty stack")?;
            stacks[to].push(x);
        }

        let n = stacks2[from].len() - n;
        let mut xs = stacks2[from].split_off(n);
        stacks2[to].append(&mut xs);
    }

    for (name, st) in [(9000, stacks), (9001, stacks2)] {
        println!("CrateMover {}: {}", name, st.iter().filter_map(|s| s.last()).collect::<String>());
    }

    Ok(())
}
