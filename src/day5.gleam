import gleam/string
import gleam/list
import gleam/io
import gleam/result
import gleam/int
import gleam/iterator.{type Iterator}

type Mapping {
  Mapping(source_start: Int, dest_start: Int, size: Int)
}

fn is_in_mapping(mapping: Mapping, n: Int) -> Bool {
  n >= mapping.source_start && n < mapping.source_start + mapping.size
}

fn apply_mapping(mapping: Mapping, n: Int) -> Int {
  n - mapping.source_start + mapping.dest_start
}

fn get_mapper(mappings: List(Mapping)) -> fn(Int) -> Int {
  fn(n) {
    case list.find(mappings, is_in_mapping(_, n)) {
      Ok(mapping) -> apply_mapping(mapping, n)
      Error(_) -> n
    }
  }
}

fn parse_number_series(numbers: String) -> List(Int) {
  let vals =
    numbers
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.values
}

fn parse_seeds(line: String) -> List(Int) {
  line
  |> string.drop_left(7)
  |> parse_number_series
}

fn parse_mappings(section: String) -> List(Mapping) {
  section
  |> string.split("\n")
  |> list.drop(1)
  |> list.map(parse_number_series)
  |> list.map(fn(numbers) {
    let assert [dest_start, source_start, size] = numbers
    Mapping(source_start, dest_start, size)
  })
}

fn parse(
  lines: String,
) -> #(
  List(Int),
  List(Mapping),
  List(Mapping),
  List(Mapping),
  List(Mapping),
  List(Mapping),
  List(Mapping),
  List(Mapping),
) {
  let sections =
    lines
    |> string.split("\n\n")

  let assert [seeds_str, ss_str, sf_str, fw_str, wl_str, lt_str, th_str, hl_str] =
    sections

  #(
    parse_seeds(seeds_str),
    parse_mappings(ss_str),
    parse_mappings(sf_str),
    parse_mappings(fw_str),
    parse_mappings(wl_str),
    parse_mappings(lt_str),
    parse_mappings(th_str),
    parse_mappings(hl_str),
  )
}

fn map(mappers: List(fn(Int) -> Int), n: Int) -> Int {
  list.fold(mappers, n, fn(val, func) { func(val) })
}

fn part1(input: String) {
  let #(seeds, ss, sf, fw, wl, lt, th, hl) = parse(input)

  let mappers =
    [ss, sf, fw, wl, lt, th, hl]
    |> list.map(get_mapper)

  let lowest =
    seeds
    |> list.map(map(mappers, _))
    |> list.reduce(int.min)
    |> io.debug

  Nil
}

fn step_range(stop: Int, step: Int) -> Iterator(Int) {
  let real_end = stop / step

  iterator.map(iterator.range(0, real_end), fn(n) { n * step })
}

fn is_in_range(n: Int, range: #(Int, Int)) -> Bool {
  n >= range.0 && n < range.0 + range.1
}

fn part2(input: String) {
  let #(seeds, ss, sf, fw, wl, lt, th, hl) = parse(input)

  let seed_ranges =
    seeds
    |> list.sized_chunk(2)
    |> list.map(fn(chunk) {
      let assert [start, stop] = chunk
      #(start, stop)
    })

  let mappers =
    [ss, sf, fw, wl, lt, th, hl]
    |> list.map(get_mapper)

  let assert Ok(#(seed0, loc0)) =
    step_range(4_294_967_296, 1000)
    |> iterator.filter(fn(n) { list.any(seed_ranges, is_in_range(n, _)) })
    |> iterator.map(fn(n) { #(n, map(mappers, n)) })
    |> iterator.reduce(fn(acc, pair) {
      case acc.1 <= pair.1 {
        True -> acc
        False -> pair
      }
    })

  let assert Ok(#(seed1, loc1)) =
    iterator.range(seed0 - 20_000, seed0 + 20_000)
    |> iterator.filter(fn(n) { list.any(seed_ranges, is_in_range(n, _)) })
    |> iterator.map(fn(n) { #(n, map(mappers, n)) })
    |> iterator.reduce(fn(acc, pair) {
      case acc.1 <= pair.1 {
        True -> acc
        False -> pair
      }
    })

  io.debug(#(seed1, loc1))
  Nil
}

pub fn main(input: String) {
  part2(input)
}
