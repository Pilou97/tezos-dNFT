#import "storage.mligo" "Storage"
#import "error.mligo" "Error"

type storage = Storage.t

type return_ = operation list * storage

type token_transfer = 
[@layout:comb]
{
    to_: address;
    token_id: nat;
    amount: nat; // always 1 in case of an nft
}

type transfer_from = {
    from_: address;
    txs: token_transfer list 
}

type transfer = transfer_from list

let handle_transfers (transfer: transfer) (storage: storage) : operation list * storage = 
    let handle_transfer (storage, transfer_from) =
        let {from_; txs} = transfer_from in 
        let {ledger; operators; token_metadata } = storage in
        let transfer_one_token (ledger, tx) = 
            let {to_; token_id; amount=_} = tx in
            Storage.transfer from_ to_ token_id ledger
        in
        let ledger = List.fold_left transfer_one_token ledger txs in
        {ledger; operators; token_metadata}
    in
    let storage = List.fold_left handle_transfer storage transfer in
    ([], storage)

// Balance of

type request = {
    owner: address;
    token_id: nat;
}

type response = [@layout:comb] {
    request: request;
    balance: nat;
}

type balance_of = [@layout:comb] {
    requests: request list;
    callback: response list contract;
}

let handle_balance_of (balance_of: balance_of) (storage: storage): operation list * storage = 
    let {requests; callback} = balance_of in
    let responses = List.map (fun request ->
        let {owner; token_id} = request in
        let balance = Storage.get_balance owner token_id storage.ledger in
        {request; balance}
    ) requests in
    let operation = Tezos.transaction responses 0tez callback in
    ([operation], storage)

// Update operators

type operator = [@layout:comb]
{
    owner: address;
    operator: address;
    token_id: nat
}

type update_operator =
    | Add_operator of operator
    | Remove_operator of operator

type update_operators = update_operator list

let handle_update_operators (update_operators: update_operators) (storage: storage): operation list * storage = 
    let {ledger; operators; token_metadata} = storage in
    let update_operator (operators, operation) = match operation with
        | Add_operator {owner; operator; token_id} -> Storage.add_operator owner operator token_id operators
        | Remove_operator {owner; operator; token_id} -> Storage.remove_operator owner operator token_id operators
    in
    let operators = List.fold_left update_operator operators update_operators in
    let storage = {ledger; operators; token_metadata} in
    ([], storage)

// Update metadata

type update = 
    | Update of bytes
    | Remove

type update_token = {
    token_id: nat;
    metadata: (string, update) map  
}

type update_metadata = update_token list

let update_token (storage, update_token: storage * update_token): storage = 
    // Some fields are reserved, so they can't be updated
    let {token_id; metadata} = update_token in
    if Map.mem "" metadata then failwith Error.fa2_reserved_metadata_field
    else if Map.mem "name" metadata then failwith Error.fa2_reserved_metadata_field
    else if Map.mem "symbol" metadata then failwith Error.fa2_reserved_metadata_field
    else if Map.mem "decimals" metadata then failwith Error.fa2_reserved_metadata_field
    else    

    // check if the token exists
    let token = Storage.get_token token_id storage in
    let token = match token with
        | None -> failwith Error.fa2_token_undefined
        | Some token -> token
    in

    let {token_id; token_info} = token in

    let update_one_field (acc, update) = 
        let (field, data) = update in
            match data with
                | Update bytes -> Map.update field (Some bytes) acc
                | Remove -> Map.update field None acc
        in
    let token_info = Map.fold update_one_field metadata token_info in
    let token = {token_id; token_info} in
    
    let storage = Storage.update_token token_id token storage in
    storage

let handle_update_metadata (update_metadata: update_metadata) (storage: storage): (operation list * storage) = 
    let operations: operation list = [] in
    let storage = List.fold_left update_token storage update_metadata in
    operations, storage

type parameters = 
    | Transfer of transfer
    | Balance_of of balance_of
    | Update_operators of update_operators
    | Update_metadata of update_metadata

let main (parameters, storage: parameters * storage) : return_ = 
    match parameters with
        | Transfer transfer -> handle_transfers transfer storage
        | Balance_of balance_of -> handle_balance_of balance_of storage
        | Update_operators update_operators -> handle_update_operators update_operators storage
        | Update_metadata update_metadata -> handle_update_metadata update_metadata storage 
