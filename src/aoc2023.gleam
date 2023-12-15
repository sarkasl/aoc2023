import gleam/io
import gleam/string
import simplifile
import day15.{main as m}

pub fn main() {
  io.println("Running aoc")

//   let input =
//     "
// rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
//     "

  let assert Ok(input) = simplifile.read("inputs/day15.txt")

  m(string.trim(input))
  Nil
}
