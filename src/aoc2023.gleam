import gleam/io
import gleam/string
import simplifile
import day9.{main as m}

pub fn main() {
  io.println("Running aoc")

//   let input =
//     "
// 0 3 6 9 12 15
// 1 3 6 10 15 21
// 10 13 16 21 30 45
//     "

  let assert Ok(input) = simplifile.read("inputs/day9.txt")

  m(string.trim(input))
  Nil
}
