import gleam/io
import gleam/string
import simplifile
import day12.{main as m}

pub fn main() {
  io.println("Running aoc")

//     let input =
//       "
// ???.### 1,1,3
// .??..??...?##. 1,1,3
// ?#?#?#?#?#?#?#? 1,3,1,6
// ????.#...#... 4,1,1
// ????.######..#####. 1,6,5
// ?###???????? 3,2,1
//       "

  let assert Ok(input) = simplifile.read("inputs/day12.txt")

  m(string.trim(input))
  Nil
}
