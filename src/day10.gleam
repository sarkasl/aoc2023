import gleam/string
import gleam/list
import gleam/dict.{type Dict}
import gleam/set.{type Set}
import gleam/io
import gleam/int
import gleam/order.{Eq}

type Direction {
  Left
  Right
  Top
  Bottom
}

type Pipe {
  BottomTop
  LeftRight
  TopRight
  TopLeft
  BottomLeft
  BottomRight
  Empty
  Start
}

type Map =
  Dict(#(Int, Int), Pipe)

fn parse_field(input: String) -> Map {
  let lines = string.split(input, "\n")
  use map, line, i <- list.index_fold(lines, dict.new())
  let graphemes = string.to_graphemes(line)
  use map, char, j <- list.index_fold(graphemes, map)
  let pipe = case char {
    "|" -> BottomTop
    "-" -> LeftRight
    "L" -> TopRight
    "J" -> TopLeft
    "7" -> BottomLeft
    "F" -> BottomRight
    "." -> Empty
    "S" -> Start
  }

  dict.insert(map, #(i, j), pipe)
}

fn parse_start(map: Map) -> #(Map, #(Int, Int)) {
  let assert [#(start_pos, _)] =
    map
    |> dict.filter(fn(_k, p) { p == Start })
    |> dict.to_list

  let top = dict.get(map, #(start_pos.0 - 1, start_pos.1))
  let bottom = dict.get(map, #(start_pos.0 + 1, start_pos.1))
  let left = dict.get(map, #(start_pos.0, start_pos.1 - 1))
  let right = dict.get(map, #(start_pos.0, start_pos.1 + 1))

  let top_in = case top {
    Ok(BottomTop) | Ok(BottomLeft) | Ok(BottomRight) -> True
    _ -> False
  }
  let bottom_in = case bottom {
    Ok(BottomTop) | Ok(TopLeft) | Ok(TopRight) -> True
    _ -> False
  }
  let left_in = case left {
    Ok(LeftRight) | Ok(BottomRight) | Ok(TopRight) -> True
    _ -> False
  }
  let right_in = case right {
    Ok(LeftRight) | Ok(BottomLeft) | Ok(TopLeft) -> True
    _ -> False
  }

  let start_pipe = case top_in, right_in, bottom_in, left_in {
    True, True, False, False -> TopRight
    True, False, True, False -> BottomTop
    True, False, False, True -> TopLeft
    False, True, True, False -> BottomRight
    False, True, False, True -> LeftRight
    False, False, True, True -> BottomLeft
    _, _, _, _ -> panic
  }

  #(dict.insert(map, start_pos, start_pipe), start_pos)
}

fn get_next_dir(pipe: Pipe, entering_dir: Direction) -> Direction {
  case pipe, entering_dir {
    BottomTop, Bottom -> Bottom
    BottomTop, Top -> Top
    LeftRight, Left -> Left
    LeftRight, Right -> Right
    TopRight, Bottom -> Right
    TopRight, Left -> Top
    TopLeft, Bottom -> Left
    TopLeft, Right -> Top
    BottomLeft, Top -> Left
    BottomLeft, Right -> Bottom
    BottomRight, Top -> Right
    BottomRight, Left -> Bottom
  }
}

fn get_next_pos(pos: #(Int, Int), dir: Direction) -> #(Int, Int) {
  case dir {
    Left -> #(pos.0, pos.1 - 1)
    Right -> #(pos.0, pos.1 + 1)
    Top -> #(pos.0 - 1, pos.1)
    Bottom -> #(pos.0 + 1, pos.1)
  }
}

fn do_step(
  map: Map,
  final_pos: #(Int, Int),
  pos: #(Int, Int),
  dir: Direction,
  acc: List(#(Int, Int)),
) -> List(#(Int, Int)) {
  case pos == final_pos {
    True -> list.reverse([pos, ..acc])
    False -> {
      let assert Ok(pipe) = dict.get(map, pos)
      let next_dir = get_next_dir(pipe, dir)
      let next_pos = get_next_pos(pos, next_dir)
      do_step(map, final_pos, next_pos, next_dir, [pos, ..acc])
    }
  }
}

fn step(map: Map, starting_pos: #(Int, Int)) -> List(#(Int, Int)) {
  let assert Ok(starting_pipe) = dict.get(map, starting_pos)
  let start_dir = case starting_pipe {
    BottomTop -> Bottom
    LeftRight -> Left
    TopRight -> Top
    TopLeft -> Top
    BottomLeft -> Bottom
    BottomRight -> Bottom
    _ -> panic
  }
  let next_pos = get_next_pos(starting_pos, start_dir)

  do_step(map, starting_pos, next_pos, start_dir, [starting_pos])
}

fn get_map_size(map: Map) -> #(Int, Int) {
  let assert Ok(biggest) =
    map
    |> dict.keys
    |> list.sort(fn(key1, key2) {
      case int.compare(key2.0, key1.0) {
        Eq -> int.compare(key2.1, key1.1)
        res -> res
      }
    })
    |> list.first
  biggest
}

fn get_contained(
  map: Map,
  steps: Set(#(Int, Int)),
  max_h: Int,
  max_w: Int,
) -> List(List(Int)) {
  use i <- list.map(list.range(0, max_h))
  let #(_, contained) = {
    use count, j <- list.map_fold(list.range(0, max_w), 0)

    let parity = count % 2
    let assert Ok(pipe) = dict.get(map, #(i, j))
    case
      pipe == TopLeft || pipe == TopRight || pipe == BottomTop,
      set.contains(steps, #(i, j))
    {
      True, True -> #(count + 1, 0)
      False, True -> #(count, 0)
      _, False -> #(count, parity)
    }
  }
  contained
}

fn part1(steps: List(#(Int, Int))) {
  steps
  |> list.length
  |> fn(l) { l / 2 }
  |> io.debug
}

fn part2(map: Map, steps: List(#(Int, Int))) {
  let edges =
    steps
    |> set.from_list

  let #(max_h, max_w) = get_map_size(map)
  let contained = get_contained(map, edges, max_h, max_w)

  contained
  |> list.map(list.fold(_, 0, int.add))
  |> list.fold(0, int.add)
  |> io.debug
}

pub fn main(input: String) {
  let #(map, start) =
    input
    |> parse_field
    |> parse_start

  let steps = step(map, start)

  part1(steps)
  part2(map, steps)

  Nil
}
