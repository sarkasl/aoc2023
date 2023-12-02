import gleam/io
import gleam/string
import simplifile
import day1.{main as m}

pub fn main() {
  io.println("Running aoc")

  // let input =
  //   "two1nine\neightwothree\nabcone2threexyz\nxtwone3four\n4nineeightseven2\nzoneight234\n7pqrstsixteen\n"

  let assert Ok(input) = simplifile.read("inputs/day1.txt")

  m(string.trim(input))
  Nil
}
