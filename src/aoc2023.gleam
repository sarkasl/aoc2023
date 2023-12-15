import gleam/io
import gleam/string
import simplifile
import day14.{main as m}
// todo
import gleam/iterator
import hyperloglog
import gleam/int
import gleam/list

pub fn main() {
  io.println("Running aoc")

  //   let input =
  //     "
  // O....#....
  // O.OO#....#
  // .....##...
  // OO.#O....O
  // .O.....O#.
  // O.#..O.#.#
  // ..O..#O..O
  // .......O..
  // #....###..
  // #OO..#....
  //     "

  let assert Ok(input) = simplifile.read("inputs/day14b.txt")

  // m(string.trim(input))

  let start = iterator.range(0, 999_999)
  let cycles =
    list.range(1_000_000, 1_099_999)
    |> iterator.from_list
    |> iterator.cycle
  let joined = iterator.concat([start, cycles])

  let #(from, cycle) =
    hyperloglog.get_cycle(joined, hyperloglog.int_to_bitarray)

  io.println(
    "Detected cycle of length " <> int.to_string(list.length(cycle)) <> " starting from index " <> int.to_string(
      from,
    ),
  )

  Nil
}
