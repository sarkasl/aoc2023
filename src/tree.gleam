import gleam/dict.{type Dict}
import gleam/result
import gleam/option.{type Option, None, Some}
import gleam/int
import gleam/list
import gleam/string
import gleam/io

pub opaque type Node(a) {
  Node(id: Int, value: a, children: List(Int), parent: Option(Int))
}

pub opaque type Tree(a) {
  Tree(root: Node(a), nodes: Dict(Int, Node(a)))
}

pub fn new_node(value: a) -> Node(a) {
  Node(
    id: int.random(-576_460_752_303_423_488, 576_460_752_303_423_487),
    parent: None,
    children: [],
    value: value,
  )
}

pub fn get_value(node: Node(a)) -> a {
  node.value
}

pub fn get_root(tree: Tree(a)) -> Node(a) {
  tree.root
}

pub fn new(root_value: a) -> Tree(a) {
  let root = new_node(root_value)
  let nodes = dict.from_list([#(root.id, root)])
  Tree(root: root, nodes: nodes)
}

pub fn from_node(root_node: Node(a)) -> Tree(a) {
  let nodes = dict.from_list([#(root_node.id, root_node)])
  Tree(root: root_node, nodes: nodes)
}

fn get_node(tree: Tree(a), node: Node(a)) -> Result(Node(a), Nil) {
  dict.get(tree.nodes, node.id)
}

pub fn get_children(tree: Tree(a), node: Node(a)) -> Result(List(Node(a)), Nil) {
  use node <- result.try(get_node(tree, node))

  node.children
  |> list.map(dict.get(tree.nodes, _))
  |> result.all
}

pub fn insert_child(
  tree: Tree(a),
  parent: Node(a),
  child: Node(a),
) -> Result(Tree(a), Nil) {
  use parent <- result.map(get_node(tree, parent))
  let modified_parent =
    Node(
      id: parent.id,
      parent: parent.parent,
      value: parent.value,
      children: [child.id, ..parent.children],
    )
  let modified_child =
    Node(
      id: child.id,
      parent: Some(parent.id),
      children: child.children,
      value: child.value,
    )

  let modified_nodes =
    tree.nodes
    |> dict.insert(child.id, modified_child)
    |> dict.insert(parent.id, modified_parent)

  case parent.id == tree.root.id {
    True -> Tree(root: modified_parent, nodes: modified_nodes)
    False -> Tree(root: tree.root, nodes: modified_nodes)
  }
}

fn do_print(tree: Tree(a), node: Node(a), indent: String) -> String {
  let assert Ok(children) = get_children(tree, node)

  case node.value, children {
    value, [] -> indent <> string.inspect(value)
    value, children -> {
      let children_indent = indent <> "  "

      children
      |> list.map(do_print(tree, _, children_indent))
      |> list.prepend(indent <> string.inspect(value))
      |> string.join("\n")
    }
  }
}

pub fn print(tree: Tree(a)) -> Nil {
  do_print(tree, tree.root, "")
  |> io.println()
}
