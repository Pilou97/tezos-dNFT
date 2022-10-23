#import "storage.mligo" "Storage"

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
        let {ledger; token_ids} = storage in
        let transfer_one_token (ledger, tx) = 
            let {to_; token_id; amount=_} = tx in
            Storage.transfer from_ to_ token_id ledger
        in
        let ledger = List.fold_left transfer_one_token ledger txs in
        {ledger; token_ids}
    in
    let storage = List.fold_left handle_transfer storage transfer in
    ([], storage)

type balance_of = unit

let handle_balance_of (balance_of: balance_of) (storage: storage): operation list * storage = 
    let operations: operation list = [] in
    (operations, storage)


type update_operators = unit

let handle_update_operators (update_operators: update_operators) (storage: storage): operation list * storage = 
    let operations: operation list = [] in
    (operations, storage)

type parameters = 
    | Transfer of transfer
    | Balance_of of balance_of
    | Update_operators of update_operators

let main (parameters, storage: parameters * storage) : return_ = 
    match parameters with
        | Transfer transfer -> handle_transfers transfer storage
        | Balance_of balance_of -> handle_balance_of balance_of storage
        | Update_operators update_operators -> handle_update_operators update_operators storage