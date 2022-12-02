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

use std::error::Error;
use std::fs::File;
use std::io::{BufRead, BufReader};

fn main() -> Result<(), Box<dyn Error>> {
    let filename = std::env::args()
        .skip(1)
        .next()
        .ok_or("No filename specified")?;

    let total = File::open(filename)
        .map(BufReader::new)?
        .lines()
        .map(|line| {
            line.map_err(Box::<dyn Error>::from).and_then(|line| {
                let (opp, outcome) = line.split_once(' ').ok_or("Invalid line")?;
                let opp = match opp {
                    "A" => 0,
                    "B" => 1,
                    "C" => 2,
                    _ => Err("Invalid opponent")?,
                };

                match outcome {
                    "X" => Ok((opp + 3 - 1) % 3 + 1),
                    "Y" => Ok(opp + 1 + 3),
                    "Z" => Ok((opp + 1) % 3 + 1 + 6),
                    _ => Err("Invalid outcome")?,
                }
            })
        })
        .try_fold(0, |acc, score| score.map(|s| acc + s))?;

    println!("{}", total);
    Ok(())
}
