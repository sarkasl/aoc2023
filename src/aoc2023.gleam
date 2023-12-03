import gleam/io
import gleam/string
import simplifile
import day3.{main as m}

pub fn main() {
  io.println("Running aoc")

  // let input =
  //   "467..114..\n...*......\n..35..633.\n......#...\n617*......\n.....+.58.\n..592.....\n......755.\n...$.*....\n.664.598.."

  let assert Ok(input) = simplifile.read("inputs/day3.txt")

  m(string.trim(input))
  Nil
}
