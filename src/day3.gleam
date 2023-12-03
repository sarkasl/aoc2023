import gleam/string
import gleam/list
import gleam/io
import gleam/int

fn is_digit(grapheme: String) -> Bool {
  case grapheme {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

fn is_symbol(grapheme: String) -> Bool {
  case is_digit(grapheme), grapheme {
    True, _ -> False
    False, "." -> False
    False, _ -> True
  }
}

fn take_number(
  line: List(#(String, Bool)),
  is_part: Bool,
  digits_acc: List(String),
) -> #(List(#(String, Bool)), Bool, List(String)) {
  case line {
    [#(value, value_is_part), ..rest] ->
      case is_digit(value), is_part || value_is_part {
        False, _ -> #(line, is_part, digits_acc)
        True, is_part -> take_number(rest, is_part, [value, ..digits_acc])
      }
    _ -> #(line, is_part, digits_acc)
  }
}

fn do_count_parts(line: List(#(String, Bool)), running_sum: Int) -> Int {
  case line {
    [] -> running_sum
    [#(value, _), ..rest] ->
      case is_digit(value) {
        True -> {
          let #(rest, is_part, digits_acc) = take_number(line, False, [])
          case is_part {
            True -> {
              let assert Ok(number) =
                digits_acc
                |> list.reverse
                |> string.concat
                |> int.parse

              do_count_parts(rest, running_sum + number)
            }
            False -> do_count_parts(rest, running_sum)
          }
        }
        False -> do_count_parts(rest, running_sum)
      }
  }
}

fn count_parts(line: List(#(String, Bool))) -> Int {
  do_count_parts(line, 0)
}

pub fn main(input: String) {
  let lines =
    input
    |> string.split("\n")

  let assert Ok(first_line) = list.first(lines)
  let padding = string.repeat(".", string.length(first_line))

  let lines = list.append([padding, ..lines], [padding])

  let sum =
    lines
    |> list.map(string.to_graphemes)
    |> list.window(3)
    |> list.map(list.transpose)
    |> list.map(list.prepend(_, [".", ".", "."]))
    |> list.map(list.append(_, [[".", ".", "."]]))
    |> list.map(list.window(_, 3))
    |> list.map(list.map(_, list.flatten))
    |> list.map(list.map(_, fn(window) {
      let assert [_, _, _, _, value, ..] = window
      #(value, list.any(window, is_symbol))
    }))
    |> list.map(count_parts)
    |> list.fold(0, int.add)

  io.debug(sum)
}
