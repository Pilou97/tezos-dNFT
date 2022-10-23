type parameters = Set of nat

type storage = {
  counter: nat
}

type return_ = operation list * storage

let set n =
  let counter = n in
  { counter }

let main (parameter, _storage: parameters * storage) : return_ =
  let operations: operation list = [] in
  let next_storage = match parameter with
    Set n -> set n
  in
  (operations, next_storage)
