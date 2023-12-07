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

fn compose_mappers(mappers: List(fn(Int) -> Int)) -> fn(Int) -> Int {
  let mapper_apply = fn(n, mapper) { mapper(n) }
  fn(n) { list.fold(mappers, n, mapper_apply) }
}

fn reverse_mapping(mapping: Mapping) -> Mapping {
  Mapping(mapping.dest_start, mapping.source_start, mapping.size)
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

fn part1(input: String) {
  let #(seeds, ss, sf, fw, wl, lt, th, hl) = parse(input)

  let mapper =
    [ss, sf, fw, wl, lt, th, hl]
    |> list.map(get_mapper)
    |> compose_mappers

  let lowest =
    seeds
    |> list.map(mapper)
    |> list.reduce(int.min)
    |> io.debug

  io.debug(lowest)
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

  let layers = [ss, sf, fw, wl, lt, th, hl]

  let layers_backwards =
    layers
    |> list.reverse
    |> list.map(list.map(_, reverse_mapping))

  let forward_mapper =
    layers
    |> list.map(get_mapper)
    |> compose_mappers

  let get_points_of_interest = fn(layer_mappings) {
    layer_mappings
    |> list.map(fn(mapping: Mapping) { mapping.source_start })
  }

  let points_of_interest =
    layers_backwards
    |> list.fold(
      [],
      fn(points, layer_mappings) {
        let poi = get_points_of_interest(layer_mappings)
        let mapper = get_mapper(layer_mappings)

        list.append(poi, points)
        |> list.map(mapper)
      },
    )

  let seed_points_of_interest =
    seed_ranges
    |> list.map(fn(range) { range.0 })

  let points_of_interest =
    list.append(seed_points_of_interest, points_of_interest)

  let assert Ok(min) =
    points_of_interest
    |> list.filter(fn(n) { list.any(seed_ranges, is_in_range(n, _)) })
    |> list.map(forward_mapper)
    |> list.reduce(int.min)

  points_of_interest
  |> list.filter(fn(n) { list.any(seed_ranges, is_in_range(n, _)) })
  |> list.length
  |> io.debug

  io.debug(list.length(points_of_interest))
  Nil
}

pub fn main(input: String) {
  // part1(input)
  part2(input)
}
