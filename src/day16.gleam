import gleam/list
import gleam/string
import gleam/io
import gleam/int
import gleam/dict.{type Dict}
import gleam/set.{type Set}
import gleam/iterator

type Pos =
  #(Int, Int)

type Room =
  Dict(Pos, String)

type Dir {
  Left
  Right
  Up
  Down
}

type Beam {
  Beam(pos: Pos, dir: Dir)
}

fn parse_room(input: String) -> #(Room, Int, Int) {
  let spaces =
    input
    |> string.split("\n")
    |> list.map(string.trim)
    |> list.map(string.to_graphemes)

  let room = {
    use room, row, i <- list.index_fold(spaces, dict.new())
    {
      use room, space, j <- list.index_fold(row, room)
      dict.insert(room, #(i, j), space)
    }
  }

  let assert Ok(first) = list.first(spaces)
  #(room, list.length(spaces), list.length(first))
}

fn move_in_dir(pos: Pos, dir: Dir) -> Pos {
  case dir {
    Up -> #(pos.0 - 1, pos.1)
    Down -> #(pos.0 + 1, pos.1)
    Left -> #(pos.0, pos.1 - 1)
    Right -> #(pos.0, pos.1 + 1)
  }
}

fn step_beam(
  room: Room,
  beam: Beam,
  visited: Set(Pos),
) -> #(List(Beam), Set(Pos)) {
  case dict.get(room, beam.pos) {
    Ok(space) -> {
      let new_visited = set.insert(visited, beam.pos)
      case beam.dir, space {
        _, "." | Left, "-" | Right, "-" | Up, "|" | Down, "|" -> {
          let new_pos = move_in_dir(beam.pos, beam.dir)
          #([Beam(new_pos, beam.dir)], new_visited)
        }
        Right, "/" | Left, "\\" -> {
          let new_dir = Up
          let new_pos = move_in_dir(beam.pos, new_dir)
          #([Beam(new_pos, new_dir)], new_visited)
        }
        Right, "\\" | Left, "/" -> {
          let new_dir = Down
          let new_pos = move_in_dir(beam.pos, new_dir)
          #([Beam(new_pos, new_dir)], new_visited)
        }
        Up, "/" | Down, "\\" -> {
          let new_dir = Right
          let new_pos = move_in_dir(beam.pos, new_dir)
          #([Beam(new_pos, new_dir)], new_visited)
        }
        Up, "\\" | Down, "/" -> {
          let new_dir = Left
          let new_pos = move_in_dir(beam.pos, new_dir)
          #([Beam(new_pos, new_dir)], new_visited)
        }
        Right, "|" | Left, "|" ->
          case set.contains(visited, beam.pos) {
            True -> #([], new_visited)
            False -> {
              let new_dir1 = Up
              let new_dir2 = Down
              let new_pos1 = move_in_dir(beam.pos, new_dir1)
              let new_pos2 = move_in_dir(beam.pos, new_dir2)
              #(
                [Beam(new_pos1, new_dir1), Beam(new_pos2, new_dir2)],
                new_visited,
              )
            }
          }

        Up, "-" | Down, "-" ->
          case set.contains(visited, beam.pos) {
            True -> #([], new_visited)
            False -> {
              let new_dir1 = Left
              let new_dir2 = Right
              let new_pos1 = move_in_dir(beam.pos, new_dir1)
              let new_pos2 = move_in_dir(beam.pos, new_dir2)
              #(
                [Beam(new_pos1, new_dir1), Beam(new_pos2, new_dir2)],
                new_visited,
              )
            }
          }
      }
    }
    Error(_) -> #([], visited)
  }
}

fn main_loop(room: Room, beams: List(Beam), visited: Set(Pos)) -> Set(Pos) {
  let #(beams, visited) = {
    use #(beams, visited), beam <- list.fold(beams, #([], visited))
    let #(new_beams, visited) = step_beam(room, beam, visited)
    #(list.append(new_beams, beams), visited)
  }

  case beams {
    [] -> visited
    _ -> main_loop(room, beams, visited)
  }
}

fn get_heat(room: Room, start_beam: Beam) -> Int {
  main_loop(room, [start_beam], set.new())
  |> set.size
}

pub fn main(input: String) {
  let #(room, width, height) = parse_room(input)

  let left_starts =
    iterator.range(0, height - 1)
    |> iterator.map(fn(i) { Beam(#(i, 0), Right) })
    |> iterator.to_list

  let right_starts =
    iterator.range(0, height - 1)
    |> iterator.map(fn(i) { Beam(#(i, width - 1), Left) })
    |> iterator.to_list

  let top_starts =
    iterator.range(0, width - 1)
    |> iterator.map(fn(i) { Beam(#(0, i), Down) })
    |> iterator.to_list

  let bottom_starts =
    iterator.range(0, width - 1)
    |> iterator.map(fn(i) { Beam(#(height - 1, i), Up) })
    |> iterator.to_list

  let starts =
    list.concat([left_starts, right_starts, top_starts, bottom_starts])

  let assert Ok(max) =
    starts
    |> list.map(get_heat(room, _))
    |> list.reduce(int.max)

  io.debug(max)

  Nil
}
