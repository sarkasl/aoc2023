import gleam/list
import gleam/string
import gleam/io
import gleam/int
import gleam/result

fn get_numbering(universe: List(List(String))) -> List(Int) {
  {
    use acc, row <- list.fold(universe, [])

    let last = result.unwrap(list.first(acc), 0)
    case list.all(row, fn(char) { char == "." }) {
      True -> [last + 1_000_000, ..acc]
      False -> [last + 1, ..acc]
    }
  }
  |> list.reverse
}

fn get_coords(universe: List(List(String))) -> List(#(Int, Int)) {
  let i_numbering =
    universe
    |> get_numbering
    |> io.debug

  let j_numbering =
    universe
    |> list.transpose
    |> get_numbering

  {
    use acc, #(row, i) <- list.fold(list.zip(universe, i_numbering), [])
    {
      use acc, #(char, j) <- list.fold(list.zip(row, j_numbering), acc)
      case char {
        "#" -> [#(i, j), ..acc]
        _ -> acc
      }
    }
  }
}

fn taxicab_dist(pair: #(#(Int, Int), #(Int, Int))) -> Int {
  let #(a, b) = pair
  int.absolute_value(a.0 - b.0) + int.absolute_value(a.1 - b.1)
}

pub fn main(input: String) {
  let universe =
    input
    |> string.split("\n")
    |> list.map(string.to_graphemes)

  let coords = get_coords(universe)

  let sum =
    coords
    |> list.combination_pairs
    |> list.map(taxicab_dist)
    |> list.fold(0, int.add)

  io.debug(sum)

  Nil
}
