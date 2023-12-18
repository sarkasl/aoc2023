import gleam/list
import gleam/string
import gleam/io
import gleam/int

type Instr {
  Left(amount: Int)
  Right(amount: Int)
  Up(amount: Int)
  Down(amount: Int)
}

fn parse_instr(line: String) -> Instr {
  let assert [dir_str, amount_str, _] = string.split(line, " ")

  let assert Ok(amount) = int.parse(amount_str)

  case dir_str {
    "R" -> Right(amount)
    "L" -> Left(amount)
    "U" -> Up(amount)
    "D" -> Down(amount)
  }
}

fn parse_instr2(line: String) -> Instr {
  let assert [_, _, color_str] = string.split(line, " ")

  let assert Ok(amount) =
    color_str
    |> string.slice(2, 5)
    |> int.base_parse(16)

  case string.slice(color_str, 7, 1) {
    "0" -> Right(amount)
    "1" -> Down(amount)
    "2" -> Left(amount)
    "3" -> Up(amount)
  }
}

fn get_area(instrs: List(Instr)) -> Int {
  let #(sum, lenght, _) = {
    use #(acc, lenght, #(x, y)), instr <- list.fold(instrs, #(0, 0, #(0, 0)))

    let #(x_next, y_next) = case instr {
      Right(amount) -> #(x + amount, y)
      Left(amount) -> #(x - amount, y)
      Down(amount) -> #(x, y + amount)
      Up(amount) -> #(x, y - amount)
    }

    let lenght = lenght + instr.amount
    let acc = acc + { { x + x_next } * { y - y_next } }

    #(acc, lenght, #(x_next, y_next))
  }

  let shoelace = int.absolute_value(sum) / 2

  shoelace + lenght / 2 + 1
}

pub fn main(input: String) {
  let lines =
    input
    |> string.split("\n")

  // part 1
  lines
  |> list.map(parse_instr)
  |> get_area
  |> io.debug

  // part 2
  lines
  |> list.map(parse_instr2)
  |> get_area
  |> io.debug

  Nil
}
