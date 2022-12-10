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

fn states<'a, L, E>(lines: &'a mut L) -> impl Iterator<Item = Result<(i32, i32), Box<dyn Error>>> + 'a
where
    L: Iterator<Item = Result<String, E>> + 'a,
    E: Error + 'static,
{
    let mut add = None;
    let mut x = 1;
    (1i32..)
        .into_iter()
        .map(move |cycle| {
            if let Some(a) = add.take() {
                x += a;
                Ok(Some((cycle, x - a)))
            } else {
                match lines.next() {
                    Some(Ok(line)) if line == "noop" => Ok(Some((cycle, x))),
                    Some(Ok(line)) if line.starts_with("addx") => {
                        let (_, n) = line.split_once(' ').ok_or("Invalid addx line")?;
                        add = Some(n.parse::<i32>()?);
                        Ok(Some((cycle, x)))
                    }
                    None => Ok(None),
                    Some(Ok(_)) => return Err("Invalid line".into()),
                    Some(Err(err)) => return Err(err.into()),
                }
            }
        })
        .take_while(|x| if let Ok(Some(_)) = x { true } else { false })
        .map(|x| x.map(|y| y.unwrap()))
}

fn main() -> Result<(), Box<dyn Error>> {
    let filename = env::args().nth(1).ok_or("Missing filename")?;
    let f = File::open(filename).map(BufReader::new)?;
    let mut lines = f.lines();

    let mut sum = 0;
    for st in states(&mut lines) {
        let (cycle, x) = st?;

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
