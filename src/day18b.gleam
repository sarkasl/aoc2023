import gleam/list
import gleam/string
import gleam/io
import gleam/int
import gleam/dict.{type Dict}
import gleam/set.{type Set}
import gleam/result
import gleam/iterator
import colours

type RGB {
  RGB(red: Int, green: Int, blue: Int)
}

type Instr {
  Left(amount: Int, color: RGB)
  Right(amount: Int, color: RGB)
  Up(amount: Int, color: RGB)
  Down(amount: Int, color: RGB)
}

fn parse_instr(line: String) -> Instr {
  let assert [dir_str, amount_str, color_str] = string.split(line, " ")

  let assert Ok(amount) = int.parse(amount_str)
  let assert [r_str, g_str, b_str] =
    color_str
    |> string.slice(2, 6)
    |> string.to_graphemes
    |> list.sized_chunk(2)
    |> list.map(string.concat)

  let assert Ok(red) = int.base_parse(r_str, 16)
  let assert Ok(green) = int.base_parse(g_str, 16)
  let assert Ok(blue) = int.base_parse(b_str, 16)
  let color = RGB(red, green, blue)

  case dir_str {
    "R" -> Right(amount, color)
    "L" -> Left(amount, color)
    "U" -> Up(amount, color)
    "D" -> Down(amount, color)
  }
}

fn parse_instr2(line: String) -> Instr {
  let assert [dir_str, _, color_str] = string.split(line, " ")

  let assert Ok(amount) =
    color_str
    |> string.slice(2, 6)
    |> int.base_parse(16)

  let color = RGB(0, 0, 0)

  case dir_str {
    "R" -> Right(amount, color)
    "L" -> Left(amount, color)
    "U" -> Up(amount, color)
    "D" -> Down(amount, color)
  }
}

type FieldValue {
  Color(RGB)
  Empty
}

type Field {
  Field(
    map: Dict(#(Int, Int), FieldValue),
    x_range: #(Int, Int),
    y_range: #(Int, Int),
  )
}

fn new_field() -> Field {
  let map = dict.new()
  Field(dict.insert(map, #(0, 0), Color(RGB(255, 255, 255))), #(0, 0), #(0, 0))
}

fn fill_empty(field: Field) -> Field {
  let #(x_min, x_max) = field.x_range
  let #(y_min, y_max) = field.y_range
  {
    use field, x <- iterator.fold(iterator.range(x_min, x_max), field)
    {
      use field, y <- iterator.fold(iterator.range(y_min, y_max), field)
      let map = case dict.get(field.map, #(x, y)) {
        Ok(_) -> field.map
        Error(_) -> dict.insert(field.map, #(x, y), Empty)
      }
      Field(map: map, x_range: field.x_range, y_range: field.y_range)
    }
  }
}

fn print_field(field: Field) -> Nil {
  let #(x_min, x_max) = field.x_range
  let #(y_min, y_max) = field.y_range
  {
    use y <- iterator.each(iterator.range(y_min, y_max))
    {
      use x <- iterator.each(iterator.range(x_min, x_max))
      let assert Ok(value) = dict.get(field.map, #(x, y))
      case value {
        Color(_) -> io.print("#")
        Empty -> io.print(".")
      }
    }
    io.println("")
  }
  Nil
}

fn fill(field: Field) -> Field {
  let #(x_min, x_max) = field.x_range
  let #(y_min, y_max) = field.y_range
  let map = {
    let y_list =
      list.range(y_min, y_max)
      |> list.window_by_2
    use map, #(y, y1) <- list.fold(y_list, field.map)
    {
      use #(map, count), x <- iterator.fold(
        iterator.range(x_min, x_max),
        #(map, 0),
      )
      let parity = count % 2

      case dict.get(map, #(x, y)), dict.get(map, #(x, y1)) {
        Ok(value), Ok(value1) ->
          case value, value1, parity {
            Color(_), Color(_), _ -> #(map, count + 1)
            Empty, _, 1 -> #(
              dict.insert(map, #(x, y), Color(RGB(255, 255, 255))),
              count,
            )
            _, _, _ -> #(map, count)
          }

        _, _ -> #(map, count)
      }
    }.0
  }
  Field(map: map, x_range: field.x_range, y_range: field.y_range)
}

fn count_field(field: Field) -> Int {
  let #(x_min, x_max) = field.x_range
  let #(y_min, y_max) = field.y_range
  {
    use acc, y <- iterator.fold(iterator.range(y_min, y_max), 0)
    {
      use acc, x <- iterator.fold(iterator.range(x_min, x_max), acc)
      let assert Ok(value) = dict.get(field.map, #(x, y))
      case value {
        Color(_) -> acc + 1
        Empty -> acc
      }
    }
  }
}

fn color_in(field: Field, pos: #(Int, Int), color: RGB) -> Field {
  let map = dict.insert(field.map, pos, Color(color))
  let #(x, y) = pos
  let #(x_min, x_max) = field.x_range
  let #(y_min, y_max) = field.y_range

  let x_min = int.min(x_min, x)
  let x_max = int.max(x_max, x)
  let y_min = int.min(y_min, y)
  let y_max = int.max(y_max, y)

  Field(map: map, x_range: #(x_min, x_max), y_range: #(y_min, y_max))
}

fn execute_instr(
  field_pos: #(#(Int, Int), Field),
  instr: Instr,
) -> #(#(Int, Int), Field) {
  let #(#(x, y), field) = field_pos

  case instr {
    Left(amount, color) -> {
      let field =
        iterator.range(x - 1, x - amount)
        |> iterator.map(fn(x) { #(x, y) })
        |> iterator.fold(field, fn(field, pos) { color_in(field, pos, color) })

      #(#(x - amount, y), field)
    }
    Right(amount, color) -> {
      let field =
        iterator.range(x + 1, x + amount)
        |> iterator.map(fn(x) { #(x, y) })
        |> iterator.fold(field, fn(field, pos) { color_in(field, pos, color) })

      #(#(x + amount, y), field)
    }
    Up(amount, color) -> {
      let field =
        iterator.range(y - 1, y - amount)
        |> iterator.map(fn(y) { #(x, y) })
        |> iterator.fold(field, fn(field, pos) { color_in(field, pos, color) })

      #(#(x, y - amount), field)
    }
    Down(amount, color) -> {
      let field =
        iterator.range(y + 1, y + amount)
        |> iterator.map(fn(y) { #(x, y) })
        |> iterator.fold(field, fn(field, pos) { color_in(field, pos, color) })

      #(#(x, y + amount), field)
    }
  }
}

pub fn main(input: String) {
  let instrs =
    input
    |> string.split("\n")
    |> list.map(parse_instr)

  let #(_, field) =
    instrs
    |> list.fold(#(#(0, 0), new_field()), execute_instr)
  let field = fill_empty(field)

  field
  |> fill
  |> count_field
  |> io.debug

  Nil
}
