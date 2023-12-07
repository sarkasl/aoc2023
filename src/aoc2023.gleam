import gleam/io
import gleam/string
import simplifile
import day7.{main as m}

pub fn main() {
  io.println("Running aoc")

//   let input =
//     "
// 32T3K 765
// T55J5 684
// KK677 28
// KTJJT 220
// QQQJA 483
//     "

  let assert Ok(input) = simplifile.read("inputs/day7.txt")

  m(string.trim(input))
  Nil
}
