import gleam/list.{Continue, Stop}
import gleam/string
import gleam/io
import gleam/int
import gleam/dict.{type Dict}
import gleam/set.{type Set}
import gleam/result
import gleam/iterator
import gleam/option.{Some}
import gleam/regex

type Section {
  Xs
  Ms
  As
  Ss
}

type Cond {
  Lt(dest: String, section: Section, n: Int)
  Gt(dest: String, section: Section, n: Int)
  Pass(dest: String)
}

type Map =
  Dict(String, List(Cond))

type Part {
  Part(x: Int, m: Int, a: Int, s: Int)
}

fn applies(cond: Cond, part: Part) {
  case cond {
    Pass(_) -> True
    Lt(_, section, _) | Gt(_, section, _) -> {
      let number = case section {
        Xs -> part.x
        Ms -> part.m
        As -> part.a
        Ss -> part.s
      }

      case cond {
        Gt(_, _, n) -> number > n
        Lt(_, _, n) -> number < n
        Pass(_) -> True
      }
    }
  }
}

fn parse(input: String) -> #(Map, List(Part)) {
  let assert [map_str, parts_str] =
    input
    |> string.split("\n\n")

  let assert Ok(map_re) = regex.from_string("([a-z]+){([^}]+)}")
  let assert Ok(parts_re) =
    regex.from_string("{x=([0-9]+),m=([0-9]+),a=([0-9]+),s=([0-9]+)}")

  let map = {
    use map, line <- list.fold(string.split(map_str, "\n"), dict.new())
    let assert [regex.Match(_, [Some(key), Some(conds)])] =
      regex.scan(map_re, line)

    let cond_list = {
      use cond <- list.map(string.split(conds, ","))

      case string.split(cond, ":") {
        [dest] -> Pass(dest)
        [c, dest] -> {
          let section = case string.slice(c, 0, 1) {
            "m" -> Ms
            "a" -> As
            "x" -> Xs
            "s" -> Ss
          }
          let assert Ok(n) =
            c
            |> string.drop_left(2)
            |> int.parse

          case string.slice(c, 1, 1) {
            ">" -> Gt(dest, section, n)
            "<" -> Lt(dest, section, n)
          }
        }
      }
    }

    dict.insert(map, key, cond_list)
  }

  let parts = {
    use line <- list.map(string.split(parts_str, "\n"))
    let assert [regex.Match(_, [Some(x), Some(m), Some(a), Some(s)])] =
      regex.scan(parts_re, line)

    let assert Ok([x, m, a, s]) =
      [x, m, a, s]
      |> list.map(int.parse)
      |> result.all

    Part(x, m, a, s)
  }

  #(map, parts)
}

fn evaluate_part(map: Map, part: Part) -> Int {
  let res = {
    use pos, _ <- iterator.fold_until(iterator.range(0, 9_999_999_999), "in")
    let assert Ok(conds) = dict.get(map, pos)

    let assert Ok(matching) =
      conds
      |> list.find(applies(_, part))
    let dest = matching.dest

    case dest {
      "A" | "R" -> Stop(dest)
      _ -> Continue(dest)
    }
  }

  case res {
    "A" -> part.a + part.m + part.x + part.s
    "R" -> 0
  }
}

pub fn main(input: String) {
  let #(map, parts) = parse(input)

  parts
  |> list.map(evaluate_part(map, _))
  // |> list.each(io.debug)
  |> list.fold(0, int.add)
  |> io.debug

  Nil
}
