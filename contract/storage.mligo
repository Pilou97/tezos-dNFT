#import "error.mligo" "Error"

type ledger = (nat, address) big_map

type operators = ((address * nat), (address set)) big_map

type metadata = {
    token_id: nat;
    token_info: (string, bytes) map
}

type t = {
    ledger: ledger;
    operators: operators;
    token_metadata: (nat, metadata) big_map;
    counter: nat;
}

let empty:t = {
    ledger = Big_map.empty;
    operators = Big_map.empty;
    token_metadata = Big_map.empty;
    counter = 0n
}

// Transfer exactly one token
let transfer (from: address) (to: address) (token_id: nat) (ledger: ledger) =
    let address = Big_map.find_opt token_id ledger in
    match address with
        | None -> // Which means the owner has 0 token, so then he can only transfer token to him self
            if from = to then ledger
            else failwith Error.fa2_insufficient_balance
        | Some owner -> if owner = from 
            then Big_map.update token_id (Some to) ledger
            else failwith Error.fa2_not_owner

let get_balance (holder: address) (token_id: nat) (storage: t) =
    let {ledger; operators=_; token_metadata=_; counter=_} = storage in
    match Big_map.find_opt token_id ledger with
        | None -> 0n
        | Some owner -> if owner = holder
            then 1n
            else 0n

let add_operator (operator: address) (owner: address) (token_id: nat) (operators: operators) = 
    let operators_set = Big_map.find_opt (owner, token_id) operators in
    let operators_set = match operators_set with
        | None -> Set.empty 
        | Some operators -> operators
    in
    let operators_set = Set.update operator true operators_set in
    Big_map.update (owner, token_id) (Some operators_set) operators

let remove_operator (operator: address) (owner: address) (token_id: nat) (operators: operators) = 
    let operators_set = Big_map.find_opt (owner, token_id) operators in
    let operators_set = match operators_set with
        | None -> Set.empty 
        | Some operators -> operators
    in
    let operators_set = Set.update operator false operators_set in
    Big_map.update (owner, token_id) (Some operators_set) operators

let get_operators (owner: address) (token_id: nat) (storage: t) = 
    let {ledger=_; operators; token_metadata=_; counter=_} = storage in
    match Big_map.find_opt (owner, token_id) operators with
        | None -> Set.empty
        | Some operators -> operators

let is_operator (operator: address) (owner: address) (token_id: nat) (operators: operators) = 
    let operators = Big_map.find_opt (owner, token_id) operators in
    match operators with
        | None -> false
        | Some operators -> Set.mem operator operators

let get_token (token_id: nat) (storage: t) = Big_map.find_opt token_id storage.token_metadata

let update_token (token_id: nat) (metadata: metadata) (storage: t) = 
    let {ledger; operators; token_metadata; counter} = storage in
    let token_metadata = Big_map.update token_id (Some metadata) token_metadata in
    {ledger; operators; token_metadata; counter}

let assert_can_transfer_token (address: address) (owner: address) (token_id: nat) (storage: t) = 
    let {ledger; operators=_; token_metadata=_; counter=_} = storage in
    let is_owner: bool = 
        match Big_map.find_opt token_id ledger with
            | None -> failwith Error.fa2_token_undefined
            | Some owner -> address = owner 
    in
    let operators = get_operators owner token_id storage in
    let is_operator = Set.mem address operators in
    if is_operator || is_owner then ()
    else failwith Error.fa2_not_operator

let assert_token_defined (token_id: nat) (storage: t) = 
    let {ledger=_; operators=_; token_metadata; counter=_} = storage in
    let token_exists = Big_map.mem token_id token_metadata in
    if token_exists then ()
    else failwith Error.fa2_token_undefined

let assert_sufficient_balance (amount: nat) (owner: address) (token_id: nat) (storage: t) =
    let balance = get_balance owner token_id storage in
    if amount <= balance then () 
    else failwith Error.fa2_insufficient_balance

let mint (owner:address) (storage:t) = 
    let {ledger; operators; token_metadata; counter} = storage in
    let metadata: metadata = {
        token_id = counter;
        token_info = Map.empty
    } in
    let _ = metadata in
    let token_metadata = Big_map.add counter metadata token_metadata in
    let ledger = Big_map.add counter owner ledger in
    let counter = counter + 1n in
    {ledger; operators; token_metadata; counter}