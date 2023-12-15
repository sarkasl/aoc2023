import gleam/list
import gleam/string
import gleam/io
import gleam/result
import gleam/int
import gleam/dict.{type Dict}
import gleam/iterator

type HashMap =
  Dict(Int, List(#(String, Int)))

type Instruction {
  Insert(label: String, value: Int)
  Remove(label: String)
}

fn parse(lens: String) -> Instruction {
  case string.contains(lens, "=") {
    True -> {
      let assert [label, value_str] = string.split(lens, "=")
      let assert Ok(value) = int.parse(value_str)
      Insert(label, value)
    }
    False -> {
      let label = string.replace(lens, "-", "")
      Remove(label)
    }
  }
}

fn hash(string: String) -> Int {
  use acc, codepoint <- list.fold(string.to_utf_codepoints(string), 0)
  let value = string.utf_codepoint_to_int(codepoint)

  { { acc + value } * 17 } % 256
}

fn run_instruction(hashmap: HashMap, instruction: Instruction) -> HashMap {
  let hash = hash(instruction.label)
  let bucket = result.unwrap(dict.get(hashmap, hash), [])

  case instruction {
    Insert(label, value) -> {
      let #(found, bucket) = {
        use dirty, key_value <- list.map_fold(bucket, False)
        let #(h_label, _) = key_value
        case label == h_label {
          True -> #(True, #(label, value))
          False -> #(dirty, key_value)
        }
      }
      case found {
        True -> dict.insert(hashmap, hash, bucket)
        False -> {
          let bucket = list.append(bucket, [#(label, value)])
          dict.insert(hashmap, hash, bucket)
        }
      }
    }
    Remove(label) -> {
      let bucket = {
        use #(h_label, _) <- list.filter(bucket)
        h_label != label
      }
      dict.insert(hashmap, hash, bucket)
    }
  }
}

fn get_focusing_power(hashmap: HashMap) -> Int {
  use acc, i <- iterator.fold(iterator.range(0, 255), 0)
  let bucket = result.unwrap(dict.get(hashmap, i), [])
  {
    use acc, #(_, value), j <- list.index_fold(bucket, acc)
    acc + { i + 1 } * { j + 1 } * value
  }
}

pub fn main(input: String) {
  let lenses =
    input
    |> string.split(",")
    |> list.map(parse)

  lenses
  |> list.fold(dict.new(), run_instruction)
  |> get_focusing_power
  |> io.debug

  Nil
}
