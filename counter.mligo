type parameters =
  | Increment of nat
  | Decrement

type storage = {
  counter: nat
}

type return_ = operation list * storage

let increment (storage: storage) nat = 
  let counter = storage.counter + nat in
  { counter }

let decrement (storage: storage) = 
  let counter = storage.counter - 1n in
  match is_nat counter with
    | Some nat_counter -> { counter = nat_counter } 
    | None -> { counter = 0n }

let main (parameter, storage: parameters * storage) : return_ =
  let operations: operation list = [] in
  let next_storage = match parameter with
    | Increment n -> increment storage n
    | Decrement -> decrement storage
  in
  (operations, next_storage)
