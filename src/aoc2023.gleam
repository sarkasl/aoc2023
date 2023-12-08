import gleam/io
import gleam/string
import simplifile
import day8.{main as m}

pub fn main() {
  io.println("Running aoc")

//   let input =
//     "
// LR

// 11A = (11B, XXX)
// 11B = (XXX, 11Z)
// 11Z = (11B, XXX)
// 22A = (22B, XXX)
// 22B = (22C, 22C)
// 22C = (22Z, 22Z)
// 22Z = (22B, 22B)
// XXX = (XXX, XXX)
//     "

  let assert Ok(input) = simplifile.read("inputs/day8.txt")

  m(string.trim(input))
  Nil
}
