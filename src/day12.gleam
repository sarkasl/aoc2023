import gleam/list
import gleam/io
import gleam/string
import gleam/int
import gleam/result
import gleam/dict.{type Dict}
import gleam/iterator

type Line {
  Line(conds: List(String), numbers: List(Int))
}

fn parse_line(line: String) -> Line {
  let assert [str_i, numbers_str] =
    line
    |> string.split(" ")
    |> list.map(string.trim)

  let assert Ok(numbers_i) =
    numbers_str
    |> string.split(",")
    |> list.map(int.parse)
    |> result.all

  let str =
    str_i
    |> list.repeat(5)
    |> list.intersperse("?")
    |> string.concat
  let numbers = list.flatten(list.repeat(numbers_i, 5))
  // let str = str_i
  // let numbers = numbers_i

  Line(string.to_graphemes(str), numbers)
}

type Branch {
  Branch(remaining: List(Int), pre: Int, weight: Int)
}

fn resolve_empty(branch: Branch) -> Result(#(List(Int), Int), Nil) {
  case branch.pre, branch.remaining {
    0, _ -> Ok(#(branch.remaining, branch.pre))
    _, [] -> Error(Nil)
    _, [next, ..rest] ->
      case branch.pre == next {
        True -> Ok(#(rest, 0))
        False -> Error(Nil)
      }
  }
}

fn resolve_full(branch: Branch) -> Result(#(List(Int), Int), Nil) {
  case branch.remaining {
    [] -> Error(Nil)
    [next, ..] ->
      case next >= branch.pre + 1 {
        True -> Ok(#(branch.remaining, branch.pre + 1))
        False -> Error(Nil)
      }
  }
}

fn count_in(
  counts: Dict(a, Int),
  weight: Int,
  res: Result(a, Nil),
) -> Dict(a, Int) {
  case res {
    Ok(key) -> {
      let count = result.unwrap(dict.get(counts, key), 0)
      dict.insert(counts, key, count + weight)
    }
    Error(_) -> counts
  }
}

fn get_option_count(line: Line) -> Int {
  // io.debug(line)

  let final_branches = {
    use branches, cond <- list.fold(line.conds, [Branch(line.numbers, 0, 1)])
    // io.debug(#(branches, cond))

    let counts = {
      use counts, branch <- list.fold(branches, dict.new())
      case cond {
        "." -> count_in(counts, branch.weight, resolve_empty(branch))
        "#" -> count_in(counts, branch.weight, resolve_full(branch))
        "?" -> {
          counts
          |> count_in(branch.weight, resolve_empty(branch))
          |> count_in(branch.weight, resolve_full(branch))
        }
      }
    }

    {
      use #(#(remaining, pre), weight) <- list.map(dict.to_list(counts))
      Branch(remaining, pre, weight)
    }
  }
  // io.debug(final_branches)

  {
    use acc, branch <- list.fold(final_branches, 0)
    case branch.remaining, branch.pre {
      [], 0 -> acc + branch.weight
      _, 0 -> acc
      [next], _ ->
        case next == branch.pre {
          True -> acc + branch.weight
          False -> acc
        }
      _, _ -> acc
    }
  }
}

pub fn main(input: String) {
  let lines =
    input
    |> string.split("\n")
    |> list.map(parse_line)

  lines
  |> list.map(get_option_count)
  // |> list.each(io.debug)
  |> list.fold(0, int.add)
  |> io.debug

  Nil
}
