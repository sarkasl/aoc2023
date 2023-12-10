import gleam_community/maths/arithmetics.{lcm}
import gleam/string
import gleam/iterator.{type Iterator}
import gleam/io
import gleam/dict.{type Dict}
import gleam/list

type Map =
  Dict(String, #(String, String))

type Movement {
  Left
  Right
}

fn parse_header(header: String) -> List(Movement) {
  let parser = fn(grapheme) {
    case grapheme {
      "R" -> Right
      "L" -> Left
    }
  }

  header
  |> string.to_graphemes
  |> list.map(parser)
}

fn parse_line(line: String) -> #(String, #(String, String)) {
  #(
    string.slice(line, 0, 3),
    #(string.slice(line, 7, 3), string.slice(line, 12, 3)),
  )
}

fn parse_map(map: String) -> #(Dict(String, #(String, String)), List(String)) {
  let lines =
    map
    |> string.split("\n")
    |> list.map(parse_line)

  let starting_positions =
    lines
    |> list.map(fn(t) { t.0 })
    |> list.filter(string.ends_with(_, "A"))

  #(dict.from_list(lines), starting_positions)
}

fn parse(input: String) -> #(Map, Iterator(Movement), List(String)) {
  let assert [header, map] = string.split(input, "\n\n")

  let instructions =
    header
    |> parse_header
    |> iterator.from_list
    |> iterator.cycle

  let #(map, starting_positions) = parse_map(map)

  #(map, instructions, starting_positions)
}

fn apply_instruction(map: Map, position: String, movement: Movement) -> String {
  let assert Ok(#(left, right)) = dict.get(map, position)
  case movement {
    Right -> right
    Left -> left
  }
}

fn do_get_cycle(
  map: Map,
  instructions: Iterator(Movement),
  starting_pos: String,
) {
  use #(pos, lenghts), instr <- iterator.fold_until(
    instructions,
    #(starting_pos, [0]),
  )

  let new_pos = apply_instruction(map, pos, instr)

  // get 2 cycle lenghts because first one is offset
  let assert [lenght, ..rest] = lenghts
  case string.ends_with(new_pos, "Z"), list.length(lenghts) {
    True, 2 -> list.Stop(#(new_pos, [lenght, ..rest]))
    True, _ -> list.Continue(#(new_pos, [1, lenght, ..rest]))
    False, _ -> list.Continue(#(new_pos, [lenght + 1, ..rest]))
  }
}

fn get_cycle(map: Map, instructions: Iterator(Movement), starting_pos: String) {
  let assert #(_, [cycle, _]) = do_get_cycle(map, instructions, starting_pos)
  cycle
}

pub fn main(input: String) {
  let #(map, instructions, starting_positions) = parse(input)
  io.debug(map)

  starting_positions
  |> list.map(get_cycle(map, instructions, _))
  |> list.fold(1, lcm)
  |> io.debug

  Nil
}
