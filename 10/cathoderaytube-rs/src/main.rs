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

fn main() -> Result<(), Box<dyn Error>> {
    let filename = env::args().nth(1).ok_or("Missing filename")?;
    let f = File::open(filename).map(BufReader::new)?;
    let mut lines = f.lines();

    let mut x = 1i32;
    let mut add: Option<i32> = None;
    let mut sum = 0;
    for cycle in 1.. {
        if cycle % 40 == 20 {
            sum += cycle * x
        }

        print!("{}", if (x - (cycle - 1) % 40).abs() <= 1 { "█" } else { " " });
        if cycle % 40 == 0 {
            println!();
        }

        if let Some(a) = add.take() {
            x += a
        } else {
            match lines.next() {
                Some(Ok(line)) if line == "noop" => (),
                Some(Ok(line)) if line.starts_with("addx") => {
                    let (_, n) = line.split_once(' ').ok_or("Invalid addx line")?;
                    add = Some(n.parse::<i32>()?);
                }
                None => break,
                Some(Ok(_)) => return Err("Invalid line".into()),
                Some(Err(err)) => return Err(err.into()),
            }
        }
    }

    println!("Final sum: {}", sum);

    Ok(())
}
