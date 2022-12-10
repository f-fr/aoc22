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

fn states<R>(input: R) -> impl Iterator<Item = Result<i32, Box<dyn Error>>>
where
    R: BufRead,
{
    let mut add = None;
    let mut x = 1;
    let mut line = String::new();
    let mut input = input;
    (1i32..).map_while(move |_| -> Option<Result<i32, Box<dyn Error>>> {
        if let Some(a) = add.take() {
            x += a;
            return Some(Ok(x - a));
        }

        line.clear();
        match input.read_line(&mut line) {
            Ok(0) => return None,
            Ok(_) => (),
            Err(err) => return Some(Err(err.into())),
        };
        let line = line.trim_end();

        if line == "noop" {
            Some(Ok(x))
        } else if let Some(("addx", n)) = line.split_once(' ') {
            match n.parse::<i32>() {
                Ok(n) => {
                    add = Some(n);
                    Some(Ok(x))
                }
                Err(err) => Some(Err(err.into())),
            }
        } else {
            return Some(Err("Invalid addx line".into()));
        }
    })
}

fn main() -> Result<(), Box<dyn Error>> {
    let filename = env::args().nth(1).ok_or("Missing filename")?;
    let f = File::open(filename).map(BufReader::new)?;

    let mut sum = 0;
    for (cycle, st) in (1..).zip(states(f)) {
        let x = st?;

        if cycle % 40 == 20 {
            sum += cycle * x
        }

        print!("{}", if (x - (cycle - 1) % 40).abs() <= 1 { "█" } else { " " });
        if cycle % 40 == 0 {
            println!();
        }
    }

    println!("Final sum: {}", sum);

    Ok(())
}
