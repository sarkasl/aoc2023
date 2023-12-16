import gleam/io
import gleam/string
import simplifile
import day16.{main as m}

pub fn main() {
  io.println("Running aoc")

//   let input =
//     "
// .|...\\....
// |.-.\\.....
// .....|-...
// ........|.
// ..........
// .........\\
// ..../.\\\\..
// .-.-/..|..
// .|....-|.\\
// ..//.|....
//     "

  let assert Ok(input) = simplifile.read("inputs/day16.txt")

  m(string.trim(input))
  Nil
}
