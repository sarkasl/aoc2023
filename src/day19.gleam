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

type Range =
  Set(Int)

type Ranges {
  Ranges(x: Range, m: Range, a: Range, s: Range)
}

type Place {
  Place(leads_in: List(String), leads_out: Dict(String, Ranges))
}

type Map =
  Dict(String, Place)

fn union(range: Ranges, other: Ranges) -> Ranges {
  Ranges(
    x: set.union(range.x, other.x),
    m: set.union(range.m, other.m),
    a: set.union(range.a, other.a),
    s: set.union(range.s, other.s),
  )
}

fn intersection(range: Ranges, other: Ranges) -> Ranges {
  Ranges(
    x: set.intersection(range.x, other.x),
    m: set.intersection(range.m, other.m),
    a: set.intersection(range.a, other.a),
    s: set.intersection(range.s, other.s),
  )
}

fn new_full() -> Ranges {
  Ranges(
    x: set.from_list(list.range(1, 4000)),
    m: set.from_list(list.range(1, 4000)),
    a: set.from_list(list.range(1, 4000)),
    s: set.from_list(list.range(1, 4000)),
  )
}

fn new_empty() -> Ranges {
  Ranges(x: set.new(), m: set.new(), a: set.new(), s: set.new())
}

fn size(ranges: Ranges) -> Int {
  set.size(ranges.x) + set.size(ranges.m) + set.size(ranges.a) + set.size(
    ranges.s,
  )
}

fn get_target_ranges(conds: String) -> Dict(String, Ranges) {
  {
    use map, cond <- list.fold(string.split(conds, ","), dict.new())

    case string.split(cond, ":") {
      [dest] -> dict.insert(map, dest, new_full())
      [c, dest] -> {
        let dest_ranges = result.unwrap(dict.get(map, dest), new_full())
        let assert Ok(n) =
          c
          |> string.drop_left(2)
          |> int.parse
        let filter = case string.slice(c, 1, 1) {
          ">" -> fn(a) { a > n }
          "<" -> fn(a) { a < n }
        }

        let dest_ranges = case string.slice(c, 0, 1) {
          "x" -> Ranges(..dest_ranges, x: set.filter(dest_ranges.x, filter))
          "m" -> Ranges(..dest_ranges, m: set.filter(dest_ranges.m, filter))
          "a" -> Ranges(..dest_ranges, a: set.filter(dest_ranges.a, filter))
          "s" -> Ranges(..dest_ranges, s: set.filter(dest_ranges.s, filter))
        }

        dict.insert(map, dest, dest_ranges)
      }
    }
  }
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

    let leads_out = get_target_ranges(conds)
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
  cache: Dict(String, a),
  node: String,
  cont: fn(Nil) -> #(Dict(String, a), a),
) -> #(Dict(String, a), a) {
  case dict.get(cache, node) {
    Ok(res) -> #(cache, res)
    Error(_) -> {
      let #(cache, res) = cont(Nil)
      let cache = dict.insert(cache, node, res)
      #(cache, res)
    }
  }
}

fn evaluate_range(
  map: Map,
  cache: Dict(String, Ranges),
  node: String,
  from: Option(String),
) -> #(Dict(String, Ranges), Ranges) {
  use _ <- use_cache(cache, node)
  let assert Ok(place) = dict.get(map, node)

  let #(cache, local_range) = case node {
    "in" -> #(cache, new_full())
    _ -> {
      use #(cache, local_range), lead_in <- list.fold(
        place.leads_in,
        #(cache, new_empty()),
      )
      let #(cache, sub_range) = evaluate_range(map, cache, lead_in, Some(node))
      #(cache, union(local_range, sub_range))
    }
  }

  case from {
    None -> {
      io.debug(#(node, size(local_range)))
      #(cache, local_range)
    }
    Some(from) -> {
      let assert Ok(lead_to_range) = dict.get(place.leads_out, from)
      let final_range = intersection(local_range, lead_to_range)
      io.debug(#(
        node,
        size(final_range),
      ))
      #(cache, final_range)
    }
  }
}

pub fn main(input: String) {
  let map = parse(input)
  io.debug(size(evaluate_range(map, dict.new(), "A", None).1))
  // map
  // |> dict.to_list
  // |> list.each(fn(z) {
  //   let #(k, p) = z
  //   io.println_error(k)
  //   {
  //     use #(k, v) <- list.each(dict.to_list(p.leads_out))
  //     io.debug(#(k, size(v)))
  //   }
  //   io.println_error("")
  // })

  Nil
}
