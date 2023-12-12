import gleam/io
import gleam/string
import simplifile
import day11.{main as m}

pub fn main() {
  io.println("Running aoc")

  let input =
    "
...#......
.......#..
#.........
..........
......#...
.#........
.........#
..........
.......#..
#...#.....
    "

  // let assert Ok(input) = simplifile.read("inputs/day11.txt")

  m(string.trim(input))
  Nil
}
