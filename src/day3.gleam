import gleam/string
import gleam/list
import gleam/io
import gleam/int

type Value {
  Number(value: Int, tag: Int)
  Gear
  Other
}

fn is_digit(grapheme: String) -> Bool {
  case grapheme {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

fn take_number(
  line: List(String),
  digits_acc: List(String),
) -> #(List(String), List(String)) {
  case line {
    [value, ..rest] ->
      case is_digit(value) {
        False -> #(line, digits_acc)
        True -> take_number(rest, [value, ..digits_acc])
      }
    _ -> #(line, digits_acc)
  }
}

fn do_parse_line(line: List(String), acc: List(Value)) -> List(Value) {
  case line {
    [] -> list.reverse(acc)
    [value, ..rest] ->
      case value, is_digit(value) {
        "*", _ -> do_parse_line(rest, [Gear, ..acc])
        _, True -> {
          let #(rest, digits_acc) = take_number(line, [])
          let assert Ok(number) =
            digits_acc
            |> list.reverse
            |> string.concat
            |> int.parse
          let result = Number(value: number, tag: int.random(0, 10_000_000))
          do_parse_line(
            rest,
            list.concat([list.repeat(result, list.length(digits_acc)), acc]),
          )
        }

        _, False -> do_parse_line(rest, [Other, ..acc])
      }
  }
}

fn parse_line(line: List(String)) -> List(Value) {
  do_parse_line(line, [])
}

pub fn main(input: String) {
  let lines =
    input
    |> string.split("\n")

  let assert Ok(first_line) = list.first(lines)
  let padding = string.repeat(".", string.length(first_line))

  let lines = list.append([padding, ..lines], [padding])
  let lines =
    lines
    |> list.map(string.to_graphemes)
    |> list.map(list.append(_, ["."]))
    |> list.map(list.prepend(_, "."))

  let sum =
    lines
    |> list.map(parse_line)
    |> list.window(3)
    |> list.map(list.transpose)
    |> list.map(list.window(_, 3))
    |> list.map(list.map(_, list.flatten))
    |> list.map(list.fold(
      _,
      0,
      fn(sum, window) {
        let assert [_, _, _, _, value, ..] = window
        let unique_numbers =
          window
          |> list.filter(fn(value) {
            case value {
              Number(_, _) -> True
              _ -> False
            }
          })
          |> list.unique
        let number_gear_ratio =
          list.fold(
            unique_numbers,
            1,
            fn(acc, number) {
              case number {
                Number(value, _) -> acc * value
                _ -> panic
              }
            },
          )

        case value, list.length(unique_numbers) {
          Gear, 2 -> sum + number_gear_ratio
          _, _ -> sum
        }
      },
    ))
    |> list.fold(0, int.add)

  io.debug(sum)
  Nil
}
