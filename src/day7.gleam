import gleam/string
import gleam/list
import gleam/io
import gleam/int
import gleam/result
import gleam/order.{type Order, Eq}
import gleam/dict.{type Dict}

fn parse_card(letter: String, part: Int) -> Int {
  case letter, part {
    "A", _ -> 14
    "K", _ -> 13
    "Q", _ -> 12
    "J", 1 -> 11
    "J", 2 -> 1
    "T", _ -> 10
    _, _ -> {
      let assert Ok(val) = int.parse(letter)
      val
    }
  }
}

fn parse_line(line: String, part: Int) -> #(List(Int), Int) {
  let assert [hand_str, bid_str] =
    line
    |> string.trim
    |> string.split(" ")

  let assert Ok(bid) = int.parse(bid_str)

  let assert [a, b, c, d, e] =
    hand_str
    |> string.to_graphemes
    |> list.map(parse_card(_, part))

  #([a, b, c, d, e], bid)
}

fn count_cards(counter: Dict(Int, Int), card: Int) -> Dict(Int, Int) {
  case dict.get(counter, card) {
    Ok(count) -> dict.insert(counter, card, count + 1)
    Error(_) -> dict.insert(counter, card, 1)
  }
}

fn get_most_amount(counted: Dict(Int, Int)) -> Int {
  counted
  |> dict.values
  |> list.sort(int.compare)
  |> list.reverse
  |> list.first
  |> result.unwrap(0)
}

fn score_amounts_p1(cards: List(Int)) -> Int {
  let counted = list.fold(cards, dict.new(), count_cards)

  case dict.size(counted) {
    1 -> 6
    2 -> {
      case get_most_amount(counted) {
        4 -> 5
        3 -> 4
      }
    }
    3 -> {
      case get_most_amount(counted) {
        3 -> 3
        2 -> 2
      }
    }
    4 -> 1
    5 -> 0
  }
}

fn score_amounts_p2(cards: List(Int)) -> Int {
  let counted = list.fold(cards, dict.new(), count_cards)
  let joker_amount =
    dict.get(counted, 1)
    |> result.unwrap(0)
  let without_joker = dict.delete(counted, 1)

  case dict.size(without_joker) {
    0 -> 6
    1 -> 6
    2 -> {
      case get_most_amount(without_joker) + joker_amount {
        4 -> 5
        3 -> 4
      }
    }
    3 -> {
      case get_most_amount(without_joker) + joker_amount {
        3 -> 3
        2 -> 2
      }
    }
    4 -> 1
    5 -> 0
  }
}

fn high_card_compare(a: #(List(Int), Int), b: #(List(Int), Int)) -> Order {
  let compare_card = fn(cards) {
    let #(a, b) = cards
    case int.compare(a, b) {
      Eq -> Error(Nil)
      res -> Ok(res)
    }
  }

  list.zip(a.0, b.0)
  |> list.find_map(compare_card)
  |> result.unwrap(Eq)
}

fn hand_compare_p1(a: #(List(Int), Int), b: #(List(Int), Int)) -> Order {
  case int.compare(score_amounts_p1(a.0), score_amounts_p1(b.0)) {
    Eq -> high_card_compare(a, b)
    res -> res
  }
}

fn hand_compare_p2(a: #(List(Int), Int), b: #(List(Int), Int)) -> Order {
  case int.compare(score_amounts_p2(a.0), score_amounts_p2(b.0)) {
    Eq -> high_card_compare(a, b)
    res -> res
  }
}

fn part1(lines: List(String)) {
  lines
  |> list.map(parse_line(_, 1))
  |> list.sort(hand_compare_p1)
  |> list.index_fold(0, fn(acc, item, index) { acc + item.1 * { index + 1 } })
  |> io.debug
}

fn part2(lines: List(String)) {
  lines
  |> list.map(parse_line(_, 2))
  |> list.sort(hand_compare_p2)
  |> list.index_fold(0, fn(acc, item, index) { acc + item.1 * { index + 1 } })
  |> io.debug
}

pub fn main(input: String) {
  let lines =
    input
    |> string.split("\n")

  // part1(lines)
  // part2(lines)

  let formatter = fn(a) {
    let #(l, _) = a
    let char_mapper = fn(n) {
      case n {
        14 -> "A"
        13 -> "K"
        12 -> "Q"
        1 -> "J"
        10 -> "T"
        _ -> int.to_string(n)
      }
    }
    l
    |> list.map(char_mapper)
    |> string.concat
  }

  lines
  |> list.map(parse_line(_, 2))
  |> list.sort(hand_compare_p2)
  |> list.map(formatter)
  |> list.each(io.println)
}
