import tree
import gleam/result

pub fn main(_input: String) {
  let silly_tree = tree.new("Root")
  let root = tree.get_root(silly_tree)

  let child1 = tree.new_node("Child 1")
  let child2 = tree.new_node("Child 2")
  let child3 = tree.new_node("Child 3")

  let assert Ok(silly_tree) =
    silly_tree
    |> tree.insert_child(root, child1)
    |> result.try(tree.insert_child(_, root, child2))
    |> result.try(tree.insert_child(_, root, child3))

  tree.print(silly_tree)

  Nil
}
