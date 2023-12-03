import gleam/string
import gleam/result
import gleam/option.{Some}
import gleam/list
import gleam/regex.{type Regex, Match}
import gleam/io
import gleam/int

fn get_highest(line: String, get_values_re: Regex) -> #(Int, Int, Int) {
  regex.scan(get_values_re, line)
  |> list.fold(
    #(0, 0, 0),
    fn(max_values, match) {
      let assert Match(_, [Some(value_str), _]) = match
      let assert Ok(value) = int.parse(value_str)
      case match {
        Match(_, [_, Some("red")]) -> #(
          int.max(max_values.0, value),
          max_values.1,
          max_values.2,
        )
        Match(_, [_, Some("green")]) -> #(
          max_values.0,
          int.max(max_values.1, value),
          max_values.2,
        )
        Match(_, [_, Some("blue")]) -> #(
          max_values.0,
          max_values.1,
          int.max(max_values.2, value),
        )
      }
    },
  )
}

fn check_line(
  line: String,
  find_id_re: Regex,
  get_values_re: Regex,
) -> Result(Int, Nil) {
  let assert [Match(_, [Some(id_str)])] = regex.scan(find_id_re, line)
  let assert Ok(id) = int.parse(id_str)

  let highest = get_highest(line, get_values_re)

  case highest.0 <= 12 && highest.1 <= 13 && highest.2 <= 14 {
    True -> Ok(id)
    False -> Error(Nil)
  }
}

fn get_line_power(line: String, get_values_re: Regex) -> Int {
  let highest = get_highest(line, get_values_re)
  highest.0 * highest.1 * highest.2
}

fn part1(lines: List(String), find_id_re: Regex, get_values_re: Regex) {
  let sum =
    lines
    |> list.map(check_line(_, find_id_re, get_values_re))
    |> result.values
    |> list.fold(0, int.add)

  io.debug(sum)
}

fn part2(lines: List(String), get_values_re: Regex) {
  let sum =
    lines
    |> list.map(get_line_power(_, get_values_re))
    |> list.fold(0, int.add)

  io.debug(sum)
}

pub fn main(input: String) {
  let lines =
    input
    |> string.split("\n")

  let assert Ok(find_id_re) = regex.from_string("^Game ([0-9]+): ")
  let assert Ok(get_values_re) = regex.from_string("([0-9]+) (red|green|blue)")

  part1(lines, find_id_re, get_values_re)
  part2(lines, get_values_re)
}
