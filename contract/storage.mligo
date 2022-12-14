#import "error.mligo" "Error"

type ledger = (nat, address) big_map

type operators = ((address * nat), (address set)) big_map

type token_id = nat

type metadata = {
    token_id: token_id;
    token_info: (string, bytes) map
}

type storage = {
    metadata: (string, bytes) big_map;
    ledger: ledger;
    operators: operators;
    token_metadata: (nat, metadata) big_map;
    counter: nat;
}

type t = storage

(* An empty storage with an url that point to the metadata of the contract. *)
let empty () : storage =
    let metadata: (string, bytes) big_map = Big_map.empty
        |> Big_map.add
            ""
            0x68747470733a2f2f63656c6c61722d63322e73657276696365732e636c657665722d636c6f75642e636f6d2f6d657461646174612f646e66742e6a736f6e
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

(**
    Transfer exactly one token from a given address to another one
     - If the owner does not have the token to be transferred, the FA2_INSUFFICIENT_BALANCE error is raised
     - if the from is not the owner of the token the FA2_NOT_OWNER error is raised
    The verification of the operators is not done in this function. But directly in the entrypoint module
*)
let transfer (from: address) (to: address) (token_id: token_id) (storage: storage) =
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

(**
    Retrieve the balance of an address for a given token
    If the owner does not have a the given token, its balance is considered to be 0.
*)
let get_balance (holder: address) (token_id: token_id) (storage: storage) =
    let {metadata=_; ledger; operators=_; token_metadata=_; counter=_} = storage in
    match Big_map.find_opt token_id ledger with
        | None -> 0n
        | Some owner -> if owner = holder
            then 1n
            else 0n

(**
    Add an operator to the given owner of a given token.
    If the the new operator is already an operator of the owner/token the function does not affect the storage.
*)
let add_operator (operator: address) (owner: address) (token_id: token_id) (storage: storage) =
    let {metadata; ledger; operators; token_metadata; counter} = storage in
    let operators_set = Big_map.find_opt (owner, token_id) operators in
    let operators_set = match operators_set with
        | None -> Set.empty
        | Some operators -> operators
    in
    let operators_set = Set.update operator true operators_set in
    let operators = Big_map.update (owner, token_id) (Some operators_set) operators in
    {metadata; ledger; operators; token_metadata; counter}

(**
    Remove the operator from the operator list of a owner/token
    If the to be removed operator is not an operator the function does not affect the storage
*)
let remove_operator (operator: address) (owner: address) (token_id: token_id) (storage: storage) =
    let {metadata; ledger; operators; token_metadata; counter} = storage in
    let operators_set = Big_map.find_opt (owner, token_id) operators in
    let operators_set = match operators_set with
        | None -> Set.empty
        | Some operators -> operators
    in
    let operators_set = Set.update operator false operators_set in
    let operators = Big_map.update (owner, token_id) (Some operators_set) operators in
    {metadata; ledger; operators; token_metadata; counter}

(**
    Returns the set of operators for a given token
*)
let get_operators (owner: address) (token_id: token_id) (storage: storage) =
    let {metadata=_; ledger=_; operators; token_metadata=_; counter=_} = storage in
    match Big_map.find_opt (owner, token_id) operators with
        | None -> Set.empty
        | Some operators -> operators

(**
    Returns true if the operator is an operator of a token for the given owner
*)
let is_operator (operator: address) (owner: address) (token_id: token_id) (operators: operators) =
    let operators = Big_map.find_opt (owner, token_id) operators in
    match operators with
        | None -> false
        | Some operators -> Set.mem operator operators

(**
    Returns true if the given address is the owner of the given token
*)
let is_owner (address: address) (token_id: token_id) (storage: storage) =
    let {metadata=_; ledger; operators=_; token_metadata=_; counter=_} = storage in
    match Big_map.find_opt token_id ledger with
        | None -> failwith Error.fa2_token_undefined
        | Some owner -> address = owner

(**
    Returns the token metadata of a given token
*)
let get_token (token_id: token_id) (storage: storage) = Big_map.find_opt token_id storage.token_metadata

(**
    Replace the token metadata by the given one.
*)
let update_token (token_id: token_id) (metadata: metadata) (storage: storage) =
    let {metadata=contract_metadata; ledger; operators; token_metadata; counter} = storage in
    let token_metadata = Big_map.update token_id (Some metadata) token_metadata in
    {metadata=contract_metadata; ledger; operators; token_metadata; counter}

(**
    Checks if the given address can transfer the token for a given user.
    To transfer a token the user has to be the owner or an operator of the user for the given token
    - If not the function raises the FA2_NOT_OPERATOR error
*)
let assert_can_transfer_token (address: address) (owner: address) (token_id: token_id) (storage: storage) =
    let is_owner = is_owner address token_id storage in
    let operators = get_operators owner token_id storage in
    let is_operator = Set.mem address operators in
    if is_operator || is_owner then ()
    else failwith Error.fa2_not_operator

(**
    Checks if the token is defined in the contract;
     - If not the function raises the FA2_TOKEN_UNDEFINED error
*)
let assert_token_defined (token_id: token_id) (storage: storage) =
    let {metadata=_; ledger=_; operators=_; token_metadata; counter=_} = storage in
    let token_exists = Big_map.mem token_id token_metadata in
    if token_exists then ()
    else failwith Error.fa2_token_undefined

(**
    Checks if the owner has enough balance compared to the given amount.
*)
let assert_sufficient_balance (amount: nat) (owner: address) (token_id: token_id) (storage: storage) =
    let balance = get_balance owner token_id storage in
    if amount <= balance then ()
    else failwith Error.fa2_insufficient_balance

(**
    Creates a new token in the ledger.
    The token won't have any metadata
    The id of the counter will be the value of the field "counter" of the contract
*)
let mint (owner:address) (storage:storage) =
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

(**
    The only person allowed to udpate the metadata if the owner of the token.
    If the address is not allowed to update the metadata of a contract the error FA2_NOT_OWNER will be raised
*)
let assert_can_update_metadata (address: address) (token_id: token_id) (storage: storage) =
    // TODO: duplicated code
    let is_owner = is_owner address token_id storage in
    if is_owner then () else failwith Error.fa2_not_owner