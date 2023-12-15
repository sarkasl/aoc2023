import gleam/int
import gleam/float
import gleam/bit_array
import gleam/iterator.{type Iterator}
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/result
import gleam/list.{Continue, Stop}
import gleam_community/maths/elementary.{logarithm_2}

type Registers =
  Dict(Int, Int)

pub opaque type HyperLogLog {
  HyperLogLog(
    n: Int,
    bits: Int,
    register_count_f: Float,
    registers: Registers,
    power_sum: Float,
    zero_count: Int,
    cardinality_est: Int,
  )
}

fn read_register(registers: Registers, address: Int) -> Int {
  result.unwrap(dict.get(registers, address), 0)
}

fn update_register(registers: Registers, address: Int, value: Int) {
  dict.insert(registers, address, value)
}

fn do_get_trailing_zero_count(hash: BitArray, bytes: Int, add: Int) -> Int {
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
      let assert Ok(hash) = bit_array.slice(hash, 0, bytes)
      do_get_trailing_zero_count(hash, bytes, add + 8)
    }
  }
}

fn get_trailing_zero_count(hash: BitArray) -> Int {
  do_get_trailing_zero_count(hash, 32, 0)
}

pub fn new(bits: Int) -> HyperLogLog {
  case bits < 8 || bits > 16 {
    True -> panic as "invalid bit range for hyperloglog (must be 8-16)"
    _ -> Nil
  }
  let assert Ok(size) = int.power(2, int.to_float(bits))
  let register_count = float.round(size)
  let register_count_f = int.to_float(register_count)

  HyperLogLog(
    0,
    bits,
    register_count_f,
    dict.new(),
    register_count_f,
    register_count,
    0,
  )
}

pub fn add(hyperloglog: HyperLogLog, value: BitArray) -> HyperLogLog {
  let n = hyperloglog.n + 1
  let bits = hyperloglog.bits
  let register_count_f = hyperloglog.register_count_f
  let hash = crypto.hash(crypto.Sha256, value)
  let assert <<register_address:size(bits), _:bits>> = hash
  let value = get_trailing_zero_count(hash)
  let original_value = read_register(hyperloglog.registers, register_address)
  case value > original_value {
    True -> {
      let assert Ok(orig_pow) =
        float.power(2.0, 0.0 -. int.to_float(original_value))
      let assert Ok(new_pow) = float.power(2.0, 0.0 -. int.to_float(value))
      let power_sum = case n % 10_000 == 0 {
        True -> {
          use acc, i <- iterator.fold(iterator.range(0, 255), 0.0)
          let v = read_register(hyperloglog.registers, i)
          let assert Ok(pow) = float.power(2.0, int.to_float(v))
          acc +. { 1.0 /. pow }
        }
        False -> hyperloglog.power_sum -. orig_pow +. new_pow
      }

      let estimate =
        { 0.7182726 *. register_count_f *. register_count_f } /. power_sum

      let zero_count = case original_value {
        0 -> hyperloglog.zero_count - 1
        _ -> hyperloglog.zero_count
      }

      let corrected = case
        estimate <. 640.0,
        zero_count,
        estimate >. 143_165_576.5
      {
        True, 0, False -> estimate
        True, _, False -> {
          let assert Ok(log) =
            logarithm_2(register_count_f /. int.to_float(zero_count))
          register_count_f *. log
        }
        False, _, True -> {
          let assert Ok(log) = logarithm_2(1.0 -. estimate /. 4_294_967_296.0)
          -4_294_967_296.0 *. log
        }
        _, _, _ -> estimate
      }

      let cardinality_est = float.round(corrected)
      let registers =
        update_register(hyperloglog.registers, register_address, value)

      HyperLogLog(
        n,
        bits,
        register_count_f,
        registers,
        power_sum,
        zero_count,
        cardinality_est,
      )
    }
    False -> hyperloglog
  }
}

pub fn estimate_cardinality(hyperloglog: HyperLogLog) -> Int {
  hyperloglog.cardinality_est
}

pub fn int_to_bitarray(n: Int) -> BitArray {
  n
  |> int.to_string
  |> bit_array.from_string
}

type State(a) {
  Settle(idx: Int, hll: HyperLogLog)
  Read(start: Int, acc: List(a), end: a)
}

pub fn get_cycle(
  iter: Iterator(a),
  to_bitarray: fn(a) -> BitArray,
) -> #(Int, List(a)) {
  let assert Read(from, acc, _) = {
    use state, item <- iterator.fold_until(iter, Settle(0, new(8)))
    case state {
      Settle(idx, hll) -> {
        let hll = add(hll, to_bitarray(item))

        let idx_f = int.to_float(idx)
        let est_cardinality_f = int.to_float(estimate_cardinality(hll))

        case est_cardinality_f <. { idx_f *. 0.75 } {
          True -> Continue(Read(idx, [item], item))
          False -> Continue(Settle(idx + 1, hll))
        }
      }
      Read(start, acc, end) ->
        case item == end {
          True -> Stop(Read(start, acc, end))
          False -> Continue(Read(start, [item, ..acc], end))
        }
    }
  }

  #(from, list.reverse(acc))
}
