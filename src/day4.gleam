import gleam/string
import gleam/int
import gleam/set.{type Set}
import gleam/list
import gleam/result
import gleam/float
import gleam/io
import gleam/dict.{type Dict}
import gleam/option.{None, Some}

fn decode_card(line: String) -> #(Int, Set(Int), Set(Int)) {
  // let positions = #(5, 1, 8, 14, 25, 23)
  let positions = #(5, 3, 10, 29, 42, 74)

  let assert Ok(id) =
    line
    |> string.slice(positions.0, positions.1)
    |> string.trim_left()
    |> int.parse

  let winning_numbers =
    line
    |> string.slice(positions.2, positions.3)
    |> string.split(" ")
    |> list.map(string.trim)
    |> list.map(int.parse)
    |> result.values
    |> set.from_list

  let your_numbers =
    line
    |> string.slice(positions.4, positions.5)
    |> string.split(" ")
    |> list.map(string.trim)
    |> list.map(int.parse)
    |> result.values
    |> set.from_list

  #(id, winning_numbers, your_numbers)
}

fn get_card_count(card_map: Dict(Int, Int), index: Int) -> Int {
  card_map
  |> dict.get(index)
  |> result.unwrap(1)
}

fn increase_card_count(
  card_dict: Dict(Int, Int),
  current_index: Int,
  count: Int,
  amount: Int,
) -> Dict(Int, Int) {
  case count {
    0 -> card_dict
    _ ->
      list.range(current_index + 1, current_index + count)
      |> list.fold(
        card_dict,
        fn(cdict, index) {
          dict.update(
            cdict,
            index,
            fn(value) {
              case value {
                Some(value) -> value + amount
                None -> 1 + amount
              }
            },
          )
        },
      )
  }
}

fn get_values_for_card(line: String) -> #(Int, Int) {
  let #(card_id, winning_numbers, your_numbers) = decode_card(line)
  let winner_amount = set.size(set.intersection(winning_numbers, your_numbers))

  #(card_id, winner_amount)
}

fn get_score(values: #(Int, Int)) -> Int {
  case values.1 {
    0 -> 0
    _ ->
      float.round(result.unwrap(int.power(2, int.to_float(values.1 - 1)), 0.0))
  }
}

fn part1(lines: List(String)) {
  let sum =
    lines
    |> list.map(get_values_for_card)
    |> list.map(get_score)
    |> list.fold(0, int.add)

  io.debug(sum)
}

fn part2(lines: List(String)) {
  let sum =
    lines
    |> list.map(get_values_for_card)
    |> list.fold(
      #(0, dict.new()),
      fn(acc, values) {
        let #(card_count, card_dict) = acc
        let #(card_id, amount) = values

        let count = get_card_count(card_dict, card_id)

        #(
          card_count + count,
          increase_card_count(card_dict, card_id, amount, count),
        )
      },
    )

  io.debug(sum.0)
}

pub fn main(input: String) {
  let lines =
    input
    |> string.split("\n")

  part1(lines)
  part2(lines)
}
// Card 209:  2 10 11 47 25 81 75 61 27  4 | 79 45 43 29 55 16 91 68 88 52 90 21 13 37 59 31  5  1 14 17 86 84 64 60 70
