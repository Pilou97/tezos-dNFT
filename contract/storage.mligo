#import "error.mligo" "Error"

type ledger = (nat, address) big_map

type operators = ((address * nat), (address set)) big_map

type metadata = {
    token_id: nat;
    token_info: (string, bytes) map
}

type t = {
    metadata: (string, bytes) big_map;
    ledger: ledger;
    operators: operators;
    token_metadata: (nat, metadata) big_map;
    counter: nat;
}

let empty () : t =
    let metadata: (string, bytes) big_map = Big_map.empty 
        |> Big_map.add "" 0x68747470733a2f2f63656c6c61722d63322e73657276696365732e636c657665722d636c6f75642e636f6d2f6d657461646174612f646e66742e6a736f6e
    in
    let ledger: ledger = Big_map.empty in
    let operators: operators = Big_map.empty in
    let token_metadata: (nat, metadata) big_map = Big_map.empty in
    let counter = 0n in
    {
        metadata;
        ledger;
        operators;
        token_metadata;
        counter;
    }

// Transfer exactly one token
let transfer (from: address) (to: address) (token_id: nat) (storage: t) =
    let {metadata; ledger; operators; token_metadata; counter} = storage in
    let address = Big_map.find_opt token_id ledger in
    match address with
        | None -> // Which means the owner has 0 token, so then he can only transfer token to him self
            if from = to then storage
            else failwith Error.fa2_insufficient_balance
        | Some owner -> if owner = from 
            then 
                let ledger = Big_map.update token_id (Some to) ledger in
                {metadata; ledger; operators; token_metadata; counter}
            else failwith Error.fa2_not_owner

let get_balance (holder: address) (token_id: nat) (storage: t) =
    let {metadata=_; ledger; operators=_; token_metadata=_; counter=_} = storage in
    match Big_map.find_opt token_id ledger with
        | None -> 0n
        | Some owner -> if owner = holder
            then 1n
            else 0n

let add_operator (operator: address) (owner: address) (token_id: nat) (storage:t) =
    let {metadata; ledger; operators; token_metadata; counter} = storage in
    let operators_set = Big_map.find_opt (owner, token_id) operators in
    let operators_set = match operators_set with
        | None -> Set.empty 
        | Some operators -> operators
    in
    let operators_set = Set.update operator true operators_set in
    let operators = Big_map.update (owner, token_id) (Some operators_set) operators in
    {metadata; ledger; operators; token_metadata; counter}

let remove_operator (operator: address) (owner: address) (token_id: nat) (storage:t) = 
    let {metadata; ledger; operators; token_metadata; counter} = storage in
    let operators_set = Big_map.find_opt (owner, token_id) operators in
    let operators_set = match operators_set with
        | None -> Set.empty 
        | Some operators -> operators
    in
    let operators_set = Set.update operator false operators_set in
    let operators = Big_map.update (owner, token_id) (Some operators_set) operators in
    {metadata; ledger; operators; token_metadata; counter}

let get_operators (owner: address) (token_id: nat) (storage: t) = 
    let {metadata=_; ledger=_; operators; token_metadata=_; counter=_} = storage in
    match Big_map.find_opt (owner, token_id) operators with
        | None -> Set.empty
        | Some operators -> operators

let is_operator (operator: address) (owner: address) (token_id: nat) (operators: operators) = 
    let operators = Big_map.find_opt (owner, token_id) operators in
    match operators with
        | None -> false
        | Some operators -> Set.mem operator operators

let is_owner (address: address) (token_id: nat) (storage: t) =
    let {metadata=_; ledger; operators=_; token_metadata=_; counter=_} = storage in
    match Big_map.find_opt token_id ledger with
        | None -> failwith Error.fa2_token_undefined
        | Some owner -> address = owner 

let get_token (token_id: nat) (storage: t) = Big_map.find_opt token_id storage.token_metadata

let update_token (token_id: nat) (metadata: metadata) (storage: t) = 
    let {metadata=contract_metadata; ledger; operators; token_metadata; counter} = storage in
    let token_metadata = Big_map.update token_id (Some metadata) token_metadata in
    {metadata=contract_metadata; ledger; operators; token_metadata; counter}

let assert_can_transfer_token (address: address) (owner: address) (token_id: nat) (storage: t) = 
    let is_owner = is_owner address token_id storage in 
    let operators = get_operators owner token_id storage in
    let is_operator = Set.mem address operators in
    if is_operator || is_owner then ()
    else failwith Error.fa2_not_operator

let assert_token_defined (token_id: nat) (storage: t) = 
    let {metadata=_; ledger=_; operators=_; token_metadata; counter=_} = storage in
    let token_exists = Big_map.mem token_id token_metadata in
    if token_exists then ()
    else failwith Error.fa2_token_undefined

let assert_sufficient_balance (amount: nat) (owner: address) (token_id: nat) (storage: t) =
    let balance = get_balance owner token_id storage in
    if amount <= balance then () 
    else failwith Error.fa2_insufficient_balance

let mint (owner:address) (storage:t) = 
    let {metadata=contract_metadata; ledger; operators; token_metadata; counter=token_id} = storage in
    let metadata: metadata = {
        token_id;
        token_info = Map.empty
    } in
    let _ = metadata in
    let token_metadata = Big_map.add token_id metadata token_metadata in
    let ledger = Big_map.add token_id owner ledger in
    let counter = token_id + 1n in
    (token_id, {metadata=contract_metadata; ledger; operators; token_metadata; counter})

let assert_can_update_metadata (address: address) (token_id: nat) (storage: t) =
    // TODO: duplicated code
    let is_owner = is_owner address token_id storage in
    if is_owner then () else failwith Error.fa2_not_owner

let assert_exists (token_id: nat) (storage: t) =
    if Big_map.mem token_id storage.token_metadata then ()
    else failwith Error.fa2_token_undefined
