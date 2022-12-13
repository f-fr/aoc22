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

use std::cmp::Ordering;
use std::env;
use std::error::Error;
use std::fs::File;
use std::io::{BufRead, BufReader};

#[derive(Clone, Debug, Eq, Ord)]
enum Node {
    Number(usize),
    List(Vec<Node>),
}

impl std::fmt::Display for Node {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            &Node::Number(n) => write!(f, "{}", n),
            &Node::List(ref children) => {
                write!(f, "[")?;
                for (i, child) in children.iter().enumerate() {
                    if i > 0 {
                        write!(f, ",")?;
                    }
                    write!(f, "{}", child)?;
                }
                write!(f, "]")
            }
        }
    }
}

impl PartialEq for Node {
    fn eq(&self, other: &Node) -> bool {
        cmp(self, other) == Ordering::Equal
    }
}

impl PartialOrd for Node {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(cmp(self, other))
    }
}

fn cmp(x: &Node, y: &Node) -> Ordering {
    use Node::*;
    match (x, y) {
        (Number(x), Number(y)) => x.cmp(y),
        (List(x), List(y)) => {
            for (x, y) in x.iter().zip(y) {
                let c = cmp(x, y);
                if c != Ordering::Equal {
                    return c;
                }
            }
            x.len().cmp(&y.len())
        }
        (x, List(y)) => {
            if y.is_empty() {
                return Ordering::Greater;
            }
            let c = cmp(x, &y[0]);
            if c != Ordering::Equal {
                c
            } else {
                1.cmp(&y.len())
            }
        }
        (List(x), y) => {
            if x.is_empty() {
                return Ordering::Less;
            }
            let c = cmp(&x[0], y);
            if c != Ordering::Equal {
                c
            } else {
                x.len().cmp(&1)
            }
        }
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    let filename = env::args().nth(1).ok_or("Missing filename")?;
    let f = File::open(filename).map(BufReader::new)?;

    let mut lines = vec![];
    for line in f.lines() {
        let line = line?;
        if !line.is_empty() {
            lines.push(parse(&line).map(|x| x.0)?);
        }
    }

    let score1 = (0..lines.len())
        .step_by(2)
        .filter(|&i| lines[i] < lines[i + 1])
        .map(|i| 1 + i / 2)
        .sum::<usize>();
    println!("Score 1: {}", score1);

    let n2 = parse("[[2]]").map(|n| n.0)?;
    let n6 = parse("[[6]]").map(|n| n.0)?;
    lines.push(n2.clone());
    lines.push(n6.clone());
    lines.sort();
    let p2 = lines.iter().position(|n| n == &n2).unwrap() + 1;
    let p6 = lines.iter().position(|n| n == &n6).unwrap() + 1;
    println!("Score 2: {}", p2 * p6);

    Ok(())
}

fn parse<'a>(line: &'a str) -> Result<(Node, &'a str), Box<dyn Error>> {
    if line.is_empty() {
        return Err("Unexpected end of input".into());
    }

    if &line[0..1] == "[" {
        if line.len() < 2 {
            return Err("Missing ']'".into());
        }
        if &line[1..2] == "]" {
            return Ok((Node::List(vec![]), &line[2..]));
        }
        let mut children = vec![];
        let mut rest = &line[1..];
        loop {
            let (child, r) = parse(rest)?;
            children.push(child);
            rest = r;
            if rest.is_empty() {
                return Err("Missing ']'".into());
            }
            if &rest[0..1] == "]" {
                return Ok((Node::List(children), &rest[1..]));
            }
            if &rest[0..1] != "," {
                return Err("Expecting ',' or ']'".into());
            }
            rest = &rest[1..];
        }
    } else {
        let end = line
            .find(|c: char| !c.is_ascii_digit())
            .unwrap_or(line.len());
        if end == 0 {
            return Err("Expected number or list".into());
        }
        Ok((Node::Number(line[..end].parse::<usize>()?), &line[end..]))
    }
}
