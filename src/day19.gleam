import gleam/list.{Continue, Stop}
import gleam/string
import gleam/io
import gleam/int
import gleam/dict.{type Dict}
import gleam/set.{type Set}
import gleam/result
import gleam/iterator.{Iterator}
import gleam/option.{type Option, None, Some}
import gleam/regex

type Range {
  Range(x: #(Int, Int), m: #(Int, Int), a: #(Int, Int), s: #(Int, Int))
}

type Comp {
  Xs
  Ms
  As
  Ss
}

type Cut {
  Lt(comp: Comp, n: Int)
  Gt(comp: Comp, n: Int)
}

type Place {
  Place(leads_in: List(String), leads_out: Dict(String, List(List(Cut))))
}

type Map =
  Dict(String, Place)

fn replace(range: Range, comp: Comp, val: #(Int, Int)) -> Range {
  case comp {
    Xs -> Range(..range, x: val)
    Ms -> Range(..range, m: val)
    As -> Range(..range, a: val)
    Ss -> Range(..range, s: val)
  }
}

fn cut(range: Range, cut: Cut) -> Option(Range) {
  let #(a, b) = case cut.comp {
    Xs -> range.x
    Ms -> range.m
    As -> range.a
    Ss -> range.s
  }

  case cut {
    Lt(_, n) ->
      case n > a, n <= b {
        False, True -> Some(range)
        True, False -> None
        True, True -> Some(replace(range, cut.comp, #(a, n - 1)))
      }
    Gt(_, n) ->
      case n >= a, n < b {
        False, True -> None
        True, False -> Some(range)
        True, True -> Some(replace(range, cut.comp, #(n + 1, b)))
      }
  }
}

fn get_cuts(conds: String) -> Dict(String, List(List(Cut))) {
  let reverse_map =
    {
      use #(map, negative), cond <- list.fold(
        string.split(conds, ","),
        #(dict.new(), []),
      )

      case string.split(cond, ":") {
        [dest] -> {
          let llc = result.unwrap(dict.get(map, dest), [])
          #(dict.insert(map, dest, [negative, ..llc]), [])
        }
        [c, dest] -> {
          let llc = result.unwrap(dict.get(map, dest), [])

          let assert Ok(n) =
            string.drop_left(c, 2)
            |> int.parse

          let comp = case string.slice(c, 0, 1) {
            "x" -> Xs
            "m" -> Ms
            "a" -> As
            "s" -> Ss
          }

          let #(new_cut, inverse_cut) = case string.slice(c, 1, 1) {
            ">" -> #(Gt(comp, n), Lt(comp, n + 1))
            "<" -> #(Lt(comp, n), Gt(comp, n - 1))
          }

          #(
            dict.insert(map, dest, [[new_cut, ..negative], ..llc]),
            [inverse_cut, ..negative],
          )
        }
      }
    }.0

  {
    use #(key, llc) <- list.map(dict.to_list(reverse_map))

    let llc =
      llc
      |> list.reverse
      |> list.map(list.reverse)

    #(key, llc)
  }
  |> dict.from_list
}

fn parse(input: String) -> Map {
  let assert [map_str, _] =
    input
    |> string.split("\n\n")

  let assert Ok(map_re) = regex.from_string("([a-z]+){([^}]+)}")

  {
    use map, line <- list.fold(string.split(map_str, "\n"), dict.new())
    let assert [regex.Match(_, [Some(key), Some(conds)])] =
      regex.scan(map_re, line)
    let place = result.unwrap(dict.get(map, key), Place([], dict.new()))

    let leads_out = get_cuts(conds)
    let map = {
      use map, dest <- list.fold(dict.keys(leads_out), map)
      let dest_place = result.unwrap(dict.get(map, dest), Place([], dict.new()))
      dict.insert(
        map,
        dest,
        Place(..dest_place, leads_in: [key, ..dest_place.leads_in]),
      )
    }

    dict.insert(map, key, Place(..place, leads_out: leads_out))
  }
}

fn use_cache(
  cache: Dict(k, v),
  node: k,
  cont: fn(Dict(k, v)) -> #(Dict(k, v), v),
) -> #(Dict(k, v), v) {
  case dict.get(cache, node) {
    Ok(res) -> #(cache, res)
    Error(_) -> {
      let #(cache, res) = cont(cache)
      #(dict.insert(cache, node, res), res)
    }
  }
}

fn evaluate_ranges(
  map: Map,
  cache: Dict(String, List(Range)),
  node: String,
) -> #(Dict(String, List(Range)), List(Range)) {
  use cache <- use_cache(cache, node)
  let assert Ok(place) = dict.get(map, node)

  case node {
    "in" -> #(cache, [Range(#(1, 4000), #(1, 4000), #(1, 4000), #(1, 4000))])
    _ -> {
      use #(cache, ranges), lead_in <- list.fold(place.leads_in, #(cache, []))
      let #(cache, sub_ranges) = evaluate_ranges(map, cache, lead_in)

      let assert Ok(Place(_, leads)) = dict.get(map, lead_in)
      let assert Ok(llc) = dict.get(leads, node)
      let cut_sub_ranges =
        {
          use lc <- list.map(llc)
          {
            use range <- list.map(sub_ranges)
            {
              use range, c <- list.fold(lc, Some(range))
              option.then(range, cut(_, c))
            }
          }
          |> option.values
        }
        |> list.concat

      #(cache, list.append(cut_sub_ranges, ranges))
    }
  }
}

fn range_size(range: Range) -> Int {
  let #(x1, x2) = range.x
  let #(m1, m2) = range.m
  let #(a1, a2) = range.a
  let #(s1, s2) = range.s

  { x2 - x1 + 1 } * { m2 - m1 + 1 } * { a2 - a1 + 1 } * { s2 - s1 + 1 }
}

fn intersection(range: Range, other: Range) -> Range {
  Range(
    x: #(int.max(range.x.0, other.x.0), int.min(range.x.1, other.x.1)),
    m: #(int.max(range.m.0, other.m.0), int.min(range.m.1, other.m.1)),
    a: #(int.max(range.a.0, other.a.0), int.min(range.a.1, other.a.1)),
    s: #(int.max(range.s.0, other.s.0), int.min(range.s.1, other.s.1)),
  )
}

fn intersection_size(ranges: List(Range)) -> Int {
  case ranges {
    [] -> 0
    [range] -> range_size(range)
    [first, ..rest] -> {
      let intersect = list.fold(rest, first, intersection)
      case
        intersect.x.0 >= intersect.x.1 || intersect.m.0 >= intersect.m.1 || intersect.a.0 >= intersect.a.1 || intersect.s.0 >= intersect.s.1
      {
        True -> 0
        False -> range_size(intersect)
      }
    }
  }
}

fn recombine(all: List(a), combinations: List(List(a))) -> List(List(a)) {
  {
    use combination <- list.flat_map(combinations)
    let combination_set = set.from_list(combination)

    let other =
      all
      |> list.filter(fn(i) { !set.contains(combination_set, i) })

    {
      use other_item <- list.map(other)
      set.insert(combination_set, other_item)
    }
  }
  |> list.unique
  |> list.map(set.to_list)
}

pub fn main(input: String) {
  let map = parse(input)
  let #(_, res) = evaluate_ranges(map, dict.new(), "A")
  let #(_, res2) = evaluate_ranges(map, dict.new(), "R")

  let intersecting = {
    use acc, range <- list.fold(res, 0)
    let intersecting =
      {
        use other <- list.map(res)
        case range == other, intersection_size([range, other]) {
          _, 0 -> 0
          False, _ -> 1
          True, _ -> 0
        }
      }
      |> list.fold(0, int.add)

    case intersecting {
      0 -> acc
      _ -> acc + 1
    }
  }

  let sum =
    res
    |> list.map(range_size)
    |> list.fold(0, int.add)

  res
  |> list.each(io.debug)

  io.debug(sum)

  // {
  //   use #(key, space) <- list.each(dict.to_list(map))
  //   io.println_error("")
  //   io.debug(key)
  //   io.debug(space.leads_out)

  //   let lcs =
  //     space.leads_out
  //     |> dict.values
  //     |> list.flatten

  //   let sum = {
  //     use acc, lc <- list.fold(lcs, 0)
  //     io.debug(lc)

  //     let assert Some(range) = {
  //       use range, c <- list.fold(
  //         lc,
  //         Some(Range(#(1, 4000), #(1, 4000), #(1, 4000), #(1, 4000))),
  //       )
  //       option.then(range, cut(_, c))
  //     }

  //     acc + range_size(range)
  //   }

  //   case key == "R" || key == "A" {
  //     True -> Nil
  //     False -> {
  //       let assert 256_000_000_000_000 = sum
  //       Nil
  //     }
  //   }

  //   io.debug(sum)
  // }

  Nil
}
