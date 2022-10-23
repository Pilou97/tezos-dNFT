type ledger = (nat, address) big_map

type t = {
    ledger: ledger;
    token_ids: nat list;
}

let transfer (from: address) (to: address) (token_id: nat) (ledger: ledger) =
    let address = Big_map.find_opt token_id ledger in
    match address with
        | None -> failwith "Token not found"
        | Some owner -> if owner = from 
            then Big_map.update token_id (Some to) ledger
            else failwith "From is not the owner of the token"

let get_balance (holder: address) (token_id: nat) (ledger: ledger) = 
    match Big_map.find_opt token_id ledger with
        | None -> 0n
        | Some owner -> if owner = holder
            then 1n
            else 0n
