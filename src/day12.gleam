import gleam/list
import gleam/io
import gleam/string
import gleam/int
import gleam/result
import gleam/iterator

type Line {
  Line(str: String, runs: List(Int), count: Int)
}

fn parse_line(line: String) -> Line {
  let assert [str_i, numbers_str] =
    line
    |> string.split(" ")
    |> list.map(string.trim)

  let str = string.repeat(str_i, 5)

  let assert Ok(numbers_i) =
    numbers_str
    |> string.split(",")
    |> list.map(int.parse)
    |> result.all

  let numbers = list.flatten(list.repeat(numbers_i, 5))

  let count =
    str
    |> string.to_graphemes
    |> list.filter(fn(char) { char == "?" })
    |> list.length

  Line(str, numbers, count)
}

fn do_combine_with_random(
  str_rem: List(String),
  random_rem: List(String),
  acc: List(String),
) -> String {
  case str_rem {
    [] -> string.concat(list.reverse(acc))
    [char, ..rest] ->
      case char {
        "?" -> {
          let assert [first_random, ..rest_random] = random_rem
          do_combine_with_random(rest, rest_random, [first_random, ..acc])
        }
        _ -> do_combine_with_random(rest, random_rem, [char, ..acc])
      }
  }
}

fn combine_with_random(str: String, random: List(String)) -> String {
  do_combine_with_random(string.to_graphemes(str), random, [])
}

fn int_to_str(n: Int, l: Int) -> List(String) {
  n
  |> int.to_base2
  |> string.pad_left(l, "0")
  |> string.to_graphemes
  |> list.map(fn(digit) {
    case digit {
      "0" -> "."
      "1" -> "#"
    }
  })
}

fn get_combinations(total_length: Int, hash_count: Int) -> List(String) {
  io.debug(#(total_length, hash_count))
  let range = list.range(0, total_length - 1)
  let combs = list.combinations(range, hash_count)

  {
    use comb <- list.map(combs)
    {
      use i <- list.map(range)
      case list.contains(comb, i) {
        True -> "#"
        False -> "."
      }
    }
  }
  |> list.map(string.concat)
}

fn get_possible(line: Line) -> List(List(String)) {
  let hash_count_str =
    line.str
    |> string.to_graphemes
    |> list.filter(fn(c) { c == "#" })
    |> list.length

  let hash_count = list.fold(line.runs, 0, int.add) - hash_count_str

  get_combinations(line.count, hash_count)
  |> list.map(string.to_graphemes)
  // |> io.debug
}

fn check_possible(str: String, random: List(String), runs: List(Int)) -> Bool {
  let final_str = combine_with_random(str, random)

  let zipped =
    final_str
    |> string.split(".")
    |> list.filter(fn(run) { string.length(run) != 0 })
    |> list.map(string.length)
    |> list.strict_zip(runs)

  case zipped {
    Ok(zipped) -> list.all(zipped, fn(t) { t.0 == t.1 })
    Error(_) -> False
  }
}

fn get_count(line: Line) -> Int {
  let possible = get_possible(line)

  possible
  |> list.filter(check_possible(line.str, _, line.runs))
  |> list.length
}

pub fn main(input: String) {
  let lines =
    input
    |> string.split("\n")
    |> list.map(parse_line)

  lines
  |> list.map(fn(line) {
    let count = get_count(line)
    io.debug(#(line.str, count))
    count
  })
  |> list.fold(0, int.add)
  |> io.debug

  Nil
}
