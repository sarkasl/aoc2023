import gleam/string
import gleam/int
import gleam/list
import gleam/io

fn read_digit(input: String) -> Result(Int, Nil) {
  case string.pop_grapheme(input) {
    Error(Nil) -> Error(Nil)
    Ok(#(grapheme, _)) -> int.parse(grapheme)
  }
}

fn read_number_forward(input: String) -> Result(Int, Nil) {
  case input {
    "" -> Error(Nil)
    _ ->
      case read_digit(input) {
        Ok(digit) -> Ok(digit)
        Error(_) ->
          case input {
            "one" <> _ -> Ok(1)
            "two" <> _ -> Ok(2)
            "three" <> _ -> Ok(3)
            "four" <> _ -> Ok(4)
            "five" <> _ -> Ok(5)
            "six" <> _ -> Ok(6)
            "seven" <> _ -> Ok(7)
            "eight" <> _ -> Ok(8)
            "nine" <> _ -> Ok(9)
            _ -> read_number_forward(string.drop_left(input, 1))
          }
      }
  }
}

fn do_read_number_backward(input: String) -> Result(Int, Nil) {
  case input {
    "" -> Error(Nil)
    _ ->
      case read_digit(input) {
        Ok(digit) -> Ok(digit)
        Error(_) ->
          case input {
            "eno" <> _ -> Ok(1)
            "owt" <> _ -> Ok(2)
            "eerht" <> _ -> Ok(3)
            "ruof" <> _ -> Ok(4)
            "evif" <> _ -> Ok(5)
            "xis" <> _ -> Ok(6)
            "neves" <> _ -> Ok(7)
            "thgie" <> _ -> Ok(8)
            "enin" <> _ -> Ok(9)
            _ -> do_read_number_backward(string.drop_left(input, 1))
          }
      }
  }
}

fn read_number_backward(input: String) -> Result(Int, Nil) {
  input
  |> string.reverse
  |> do_read_number_backward
}

fn get_number_from_line(line: String) -> Int {
  let assert Ok(forward) = read_number_forward(line)
  let assert Ok(backward) = read_number_backward(line)

  let assert Ok(result) =
    int.parse(int.to_string(forward) <> int.to_string(backward))

  result
}

pub fn main(input: String) {
  let lines =
    input
    |> string.split("\n")

  lines
  |> list.map(get_number_from_line)
  |> list.fold(0, int.add)
  |> io.debug
}
