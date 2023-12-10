import gleam/io
import gleam/string
import simplifile
import day10.{main as m}

pub fn main() {
  io.println("Running aoc")

//   let input =
//     "
// FF7FSF7F7F7F7F7F---7
// L|LJ||||||||||||F--J
// FL-7LJLJ||||||LJL-77
// F--JF--7||LJLJ7F7FJ-
// L---JF-JLJ.||-FJLJJ7
// |F|F-JF---7F7-L7L|7|
// |FFJF7L7F-JF7|JL---7
// 7-L-JL7||F7|L7F-7F7|
// L.L7LFJ|||||FJL7||LJ
// L7JLJL-JLJLJL--JLJ.L
//     "

  let assert Ok(input) = simplifile.read("inputs/day10.txt")

  m(string.trim(input))
  Nil
}
