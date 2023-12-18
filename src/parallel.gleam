import gleam/otp/task
import gleam/list

pub fn list_map(list: List(a), with fun: fn(a) -> b) -> List(b) {
  {
    use item <- list.map(list)
    task.async(fn() { fun(item) })
  }
  |> list.map(task.await(_, 864_000))
}
