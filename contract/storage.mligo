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
}

let transfer (from: address) (to: address) (token_id: nat) (ledger: ledger) =
    let address = Big_map.find_opt token_id ledger in
    match address with
        | None -> failwith Error.fa2_insufficient_balance
        | Some owner -> if owner = from 
            then Big_map.update token_id (Some to) ledger
            else failwith Error.fa2_not_owner

let get_balance (holder: address) (token_id: nat) (ledger: ledger) = 
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

let is_operator (operator: address) (owner: address) (token_id: nat) (operators: operators) = 
    let operators = Big_map.find_opt (owner, token_id) operators in
    match operators with
        | None -> false
        | Some operators -> Set.mem operator operators

let get_token (token_id: nat) (storage: t) = Big_map.find_opt token_id storage.token_metadata

let update_token (token_id: nat) (metadata: metadata) (storage: t) = 
    let {ledger; operators; token_metadata} = storage in
    let token_metadata = Big_map.update token_id (Some metadata) token_metadata in
    {ledger; operators; token_metadata}
