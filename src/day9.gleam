import gleam/io
import gleam/string
import gleam/list
import gleam/int
import gleam/result

fn diff(l: List(List(Int))) -> List(List(Int)) {
  let assert Ok(last) = list.first(l)
  let assert new_last =
    last
    |> list.window_by_2
    |> list.map(fn(t) { t.1 - t.0 })

  [new_last, ..l]
}

fn all_zeroes(l: List(List(Int))) -> Bool {
  let assert Ok(last) = list.first(l)
  list.all(last, fn(n) { n == 0 })
}

fn get_all_zeroes(l: List(List(Int))) -> List(List(Int)) {
  case all_zeroes(l) {
    True -> l
    False -> get_all_zeroes(diff(l))
  }
}

fn add_zero(l: List(List(Int))) -> List(List(Int)) {
  let assert [last, ..rest] = l
  [[0, ..last], ..rest]
}

fn reconstruct_layer(lower: List(Int), layer: List(Int)) -> List(Int) {
  let assert Ok(first_n) = list.first(layer)

  lower
  |> list.fold(
    [first_n],
    fn(acc, diff) {
      let assert Ok(first) = list.first(acc)
      [first + diff, ..acc]
    },
  )
  |> list.reverse
}

fn reconstruct(l: List(List(Int))) -> List(List(Int)) {
  case l {
    [lower, layer, ..rest] ->
      reconstruct([reconstruct_layer(lower, layer), ..rest])
    _ -> l
  }
}

fn get_new_addition(numbers: List(Int)) -> Int {
  let assert [res] =
    [numbers]
    |> get_all_zeroes
    |> add_zero
    |> reconstruct
  let assert Ok(last) = list.last(res)
  last
}

fn parse_line(line: String) {
  let assert Ok(series) =
    line
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.all
  series
}

fn part1(series: List(List(Int))) {
  series
  |> list.map(get_new_addition)
  |> list.fold(0, int.add)
  |> io.debug

  Nil
}

fn part2(series: List(List(Int))) {
  series
  |> list.map(list.reverse)
  |> list.map(get_new_addition)
  |> list.fold(0, int.add)
  |> io.debug

  Nil
}

pub fn main(input: String) {
  let series =
    input
    |> string.split("\n")
    |> list.map(parse_line)

  part2(series)
}
