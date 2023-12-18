import gleam/list
import gleam/string
import gleam/io
import gleam/int
import gleam/dict.{type Dict}
import gleam/set.{type Set}
import gleam/result
import gleam/iterator

type NodeType {
  Hnode
  Vnode
}

type Node {
  Start
  End
  Node(n: Int, m: Int, t: NodeType, z: Int)
}

type Link {
  Link(node: Node, weight: Int)
}

type Room =
  Dict(Node, List(Link))

fn generate_room(h: Int, v: Int, max_move: Int) -> Room {
  let n_max = h
  let m_max = v
  let z_min = 2
  let z_max = max_move

  let end_nodes = {
    use z <- list.flat_map(list.range(z_min, z_max))
    [Node(n_max, m_max, Hnode, z), Node(n_max, m_max, Vnode, z)]
  }

  let start_nodes = [Node(1, 1, Hnode, 1), Node(1, 1, Vnode, 1)]

  let room =
    {
      use room, n <- iterator.fold(iterator.range(1, n_max), dict.new())
      {
        use room, m <- iterator.fold(iterator.range(1, m_max), room)
        {
          use room, z <- iterator.fold(iterator.range(z_min, z_max), room)

          room
          |> dict.insert(Node(n, m, Hnode, z), [])
          |> dict.insert(Node(n, m, Vnode, z), [])
        }
      }
    }
    |> dict.insert(Start, [])
    |> dict.insert(End, [])

  let room = {
    use room, start_node <- list.fold(start_nodes, room)
    dict.insert(room, start_node, [])
  }

  {
    use room, node <- list.fold(end_nodes, room)
    dict.insert(room, node, [Link(End, 0)])
  }
}

fn add_link(
  room: Room,
  weights: Dict(#(Int, Int), Int),
  from: Node,
  to: Node,
) -> Room {
  case to {
    Node(n, m, _, _) ->
      case
        dict.get(room, from),
        dict.get(room, to),
        dict.get(weights, #(n, m))
      {
        Ok(links), Ok(_), Ok(weight) ->
          dict.insert(room, from, [Link(to, weight), ..links])
        _, _, _ -> room
      }
    _ -> room
  }
}

fn add_links(
  room: Room,
  weights: Dict(#(Int, Int), Int),
  n: Int,
  m: Int,
  z: Int,
) -> Room {
  let ma1 = #(n, m + 1, Hnode)
  let ma2 = #(n, m - 1, Hnode)
  let mb1 = #(n + 1, m, Vnode)
  let mb2 = #(n - 1, m, Vnode)

  let make_target = fn(c: #(Int, Int, NodeType), z: Int) {
    Node(c.0, c.1, c.2, z)
  }

  let h_links = [
    make_target(ma1, z + 1),
    make_target(ma2, z + 1),
    make_target(mb1, 2),
    make_target(mb2, 2),
  ]

  let v_links = [
    make_target(ma1, 2),
    make_target(ma2, 2),
    make_target(mb1, z + 1),
    make_target(mb2, z + 1),
  ]

  let h_from = Node(n, m, Hnode, z)
  let room = {
    use room, to <- list.fold(h_links, room)
    add_link(room, weights, h_from, to)
  }

  let v_from = Node(n, m, Vnode, z)
  {
    use room, to <- list.fold(v_links, room)
    add_link(room, weights, v_from, to)
  }
}

fn parse(input: String, max_move: Int) -> Room {
  let assert Ok(weights) =
    input
    |> string.split("\n")
    |> list.map(string.to_graphemes)
    |> list.map(list.map(_, int.parse))
    |> list.map(result.all)
    |> result.all
  let assert Ok(first_row) = list.first(weights)
  let assert Ok(first_value) = list.first(first_row)

  let h = list.length(first_row)
  let v = list.length(weights)

  // generate room without links
  let room = generate_room(h, v, max_move)

  // create weights
  let weights = {
    use weights, row, i <- list.index_fold(weights, dict.new())
    {
      use weights, weight, j <- list.index_fold(row, weights)
      dict.insert(weights, #(i + 1, j + 1), weight)
    }
  }

  // create links
  let room =
    {
      use room, n <- iterator.fold(iterator.range(1, h), room)
      {
        use room, m <- iterator.fold(iterator.range(1, v), room)
        {
          use room, z <- iterator.fold(iterator.range(2, max_move), room)
          add_links(room, weights, n, m, z)
        }
      }
    }
    |> add_links(weights, 1, 1, 1)

  // create links from start
  let start_node_links = [
    Link(Node(1, 1, Hnode, 1), first_value),
    Link(Node(1, 1, Vnode, 1), first_value),
  ]
  room
  |> dict.insert(Start, start_node_links)
}

pub fn main(input: String) {
  let room = parse(input, 2)

  room
  |> dict.to_list
  |> list.each(io.debug)
  Nil
}
