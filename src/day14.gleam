import gleam/string
import gleam/list.{Continue, Stop}
import gleam/io
import gleam/iterator
import gleam/int
import gleam/float
import gleam/bytes_builder
import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/result

type Dish =
  List(List(String))

fn parse(input: String) {
  input
  |> string.split("\n")
  |> list.map(string.to_graphemes)
}

fn do_tilt_row(
  row: List(String),
  acc: List(String),
  counter_empty: Int,
  counter_rocks: Int,
) -> List(String) {
  let get_new_acc = fn(acc, counter_empty, counter_rocks) {
    list.concat([
      list.repeat("O", counter_rocks),
      list.repeat(".", counter_empty),
      acc,
    ])
  }

  case row {
    [".", ..rest] -> do_tilt_row(rest, acc, counter_empty + 1, counter_rocks)
    ["O", ..rest] -> do_tilt_row(rest, acc, counter_empty, counter_rocks + 1)
    ["#", ..rest] -> {
      let new_acc = ["#", ..get_new_acc(acc, counter_empty, counter_rocks)]
      do_tilt_row(rest, new_acc, 0, 0)
    }
    [] -> list.reverse(get_new_acc(acc, counter_empty, counter_rocks))
  }
}

fn tilt_row(row: List(String)) -> List(String) {
  do_tilt_row(row, [], 0, 0)
}

fn count_load(dish: Dish) -> Int {
  use acc, row, idx <- list.index_fold(list.reverse(dish), 0)
  let weight = idx + 1
  {
    use acc, char <- list.fold(row, acc)
    case char {
      "O" -> acc + weight
      _ -> acc
    }
  }
}

fn hash_dish(dish: Dish) -> BitArray {
  {
    use acc, row <- list.fold(dish, bytes_builder.new())

    row
    |> string.concat
    |> bit_array.from_string
    |> bytes_builder.append(acc, _)
  }
  |> bytes_builder.to_bit_array
  |> crypto.hash(crypto.Sha256, _)
}

type Registers =
  Dict(Int, Int)

fn read_register(registers: Registers, address: Int) -> Int {
  result.unwrap(dict.get(registers, address), 0)
}

fn update_register(registers: Registers, address: Int, value: Int) {
  dict.insert(registers, address, value)
}

fn get_trailing_zero_count(hash: BitArray, bytes: Int, add: Int) -> Int {
  let bytes = bytes - 1
  case hash {
    <<_:size(bytes)-unit(8), _:7, 1:1>> -> 1 + add
    <<_:size(bytes)-unit(8), _:6, 2:2>> -> 2 + add
    <<_:size(bytes)-unit(8), _:5, 4:3>> -> 3 + add
    <<_:size(bytes)-unit(8), _:4, 8:4>> -> 4 + add
    <<_:size(bytes)-unit(8), _:3, 16:5>> -> 5 + add
    <<_:size(bytes)-unit(8), _:2, 32:6>> -> 6 + add
    <<_:size(bytes)-unit(8), _:1, 64:7>> -> 7 + add
    <<_:size(bytes)-unit(8), 128:8>> -> 8 + add
    _ -> {
      io.debug(#(hash, 8 * bytes))
      let assert Ok(hash) = bit_array.slice(hash, 0, bytes)
      get_trailing_zero_count(hash, bytes, add + 8)
    }
  }
}

fn hyperloglog_add(registers: Registers, hash: BitArray) -> Registers {
  let <<register_address:8, _:bits>> = hash

  // let value = case hash {
  //   <<_:255, 1:1>> -> 1
  //   <<_:254, 2:2>> -> 2
  //   <<_:253, 4:3>> -> 3
  //   <<_:252, 8:4>> -> 4
  //   <<_:251, 16:5>> -> 5
  //   <<_:250, 32:6>> -> 6
  //   <<_:249, 64:7>> -> 7
  //   <<_:248, 128:8>> -> 8
  //   _ -> panic
  // }
  let value = get_trailing_zero_count(hash, 32, 0)

  let value = int.max(value, read_register(registers, register_address))

  update_register(registers, register_address, value)
}

fn hyperloglog_count(registers: Registers) -> Int {
  let count = {
    use acc, i <- iterator.fold(iterator.range(0, 255), 0.0)
    let v = read_register(registers, i)
    let assert Ok(pow) = float.power(2.0, int.to_float(v))
    acc +. { 1.0 /. pow }
  }

  let estimate = { 0.7182726 *. 65_536.0 } /. count
  float.round(estimate)
}

type State {
  Settle(dish: Dish, registers: Registers)
  Measure(dish: Dish)
  Seek(dish: Dish, target: Int)
}

fn run_cycle(dish_pn: Dish) {
  dish_pn
  //N
  |> list.map(tilt_row)
  |> list.transpose
  |> list.map(list.reverse)
  // W
  |> list.map(tilt_row)
  |> list.transpose
  |> list.map(list.reverse)
  // S
  |> list.map(tilt_row)
  |> list.transpose
  |> list.map(list.reverse)
  // E
  |> list.map(tilt_row)
  |> list.transpose
  |> list.map(list.reverse)
}

fn run_cycles(dish: List(List(String))) -> List(List(String)) {
  let pointing_north =
    dish
    |> list.transpose
    |> list.map(list.reverse)

  let tumbled = {
    // 999_999_999
    use state, i <- iterator.fold_until(
      iterator.range(0, 500),
      Settle(pointing_north, dict.new()),
    )

    case i % 1000 {
      0 -> {
        io.println(int.to_string(i))
        Nil
      }
      _ -> Nil
    }

    case state {
      Settle(pointing_north, registers) -> {
        let new_dish = run_cycle(pointing_north)
        let hash = hash_dish(new_dish)
        let registers = hyperloglog_add(registers, hash)
        let est = hyperloglog_count(registers)
        io.debug(#(i, est))
        Continue(Settle(new_dish, registers))
      }
      _ -> panic
    }
  }

  tumbled.dish
  |> list.map(list.reverse)
  |> list.transpose
}

pub fn main(input: String) {
  let dish = parse(input)

  dish
  |> run_cycles
  |> count_load
  |> io.debug
}
