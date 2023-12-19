import gleam/list
import gleam/string
import gleam/io
import gleam/int
import gleam/result

fn find_mirror(field: List(List(String))) -> Int {
  {
    use i <- list.find_map(list.range(1, list.length(field) - 1))

    let #(p1, p2) = list.split(field, i)
    let min_l = int.min(list.length(p1), list.length(p2))
    let p1 = list.flatten(list.take(list.reverse(p1), min_l))
    let p2 = list.flatten(list.take(p2, min_l))

    let mirrorness = {
      use mirrorness, #(a, b) <- list.fold(list.zip(p1, p2), 0)
      case a == b {
        True -> mirrorness
        False -> mirrorness - 1
      }
    }

    case mirrorness {
      -1 -> Ok(i)
      _ -> Error(Nil)
    }
  }
  |> result.unwrap(0)
}

pub fn main(input: String) {
  let fields =
    input
    |> string.split("\n\n")
    |> list.map(string.split(_, "\n"))
    |> list.map(list.map(_, string.to_graphemes))

  {
    use field <- list.map(fields)

    let rows =
      field
      |> find_mirror

    let cols =
      field
      |> list.transpose
      |> find_mirror

    100 * rows + cols
  }
  |> list.fold(0, int.add)
  |> io.debug
}
