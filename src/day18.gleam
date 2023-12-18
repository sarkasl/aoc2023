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

fn get_polygon(instrs: List(Instr)) -> List(#(Int, Int)) {
  let assert Ok(first) = list.first(instrs)
  let circular =
    instrs
    |> list.append([first])
    |> list.window_by_2

  {
    use #(acc, #(x, y)), #(instr, next) <- list.fold(circular, #([], #(0, 0)))

    let pos = case instr {
      Right(amount) -> #(x + 2 * amount, y)
      Left(amount) -> #(x - 2 * amount, y)
      Down(amount) -> #(x, y + 2 * amount)
      Up(amount) -> #(x, y - 2 * amount)
    }

    let offset = case instr, next {
      Right(_), Down(_) | Down(_), Right(_) -> #(1, -1)
      Right(_), Up(_) | Up(_), Right(_) -> #(-1, -1)
      Left(_), Down(_) | Down(_), Left(_) -> #(1, 1)
      Left(_), Up(_) | Up(_), Left(_) -> #(-1, 1)
    }

    #([#(pos.0 + offset.0, pos.1 + offset.1), ..acc], pos)
  }.0
}

fn polygon_area(polygon: List(#(Int, Int))) -> Int {
  let assert Ok(last) = list.last(polygon)
  let circular =
    [last, ..polygon]
    |> list.window_by_2

  let sum = {
    use acc, #(#(x, y), #(x1, y1)) <- list.fold(circular, 0)
    acc + { { x + x1 } * { y - y1 } }
  }
  int.absolute_value(sum) / 2
}

fn get_area(instrs: List(Instr)) {
  let area_x4 =
    instrs
    |> get_polygon
    |> polygon_area

  area_x4 / 4
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
