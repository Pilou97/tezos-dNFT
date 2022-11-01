#import "./common.mligo" "Common"
#import "../storage.mligo" "Storage"
#import "../main.mligo" "Main"

let mint_increments_counter () =
    let prev = Storage.empty in
    let (next, result) = Common.transfer prev (Mint_token ()) in
    let counter = next.counter in
    let () = assert (counter = 1n) in
    Common.assert_success result

let mint_add_metadata () = 
    let prev = Storage.empty in
    let previous_metadata = Big_map.mem 0n prev.token_metadata in
    let next, result = Common.transfer prev (Mint_token ()) in
    let next_metadata = Big_map.mem 0n next.token_metadata in
    let () = assert (previous_metadata = false) in
    let () = assert (next_metadata = true) in
    Common.assert_success result

let mint_empty_token_info () = 
    let prev = Storage.empty in
    let next, result = Common.transfer prev (Mint_token ()) in
    let token_metadata = Big_map.find_opt 0n next.token_metadata |> Option.unopt in
    let { token_id=_; token_info } = token_metadata in 
    let size = Map.size token_info in
    let () = assert (size = 0n) in
    Common.assert_success result

let mint_token_good_token_id () = 
    let prev = Storage.empty in
    let counter = prev.counter in
    let next, result = Common.transfer prev (Mint_token ()) in
    let token_metadata = Big_map.find_opt 0n next.token_metadata |> Option.unopt in
    let { token_id; token_info = _ } = token_metadata in 
    let () = assert (counter = token_id) in
    Common.assert_success result

let mint_token_has_owner () = 
    let prev = Storage.empty in
    let next, result = Common.transfer prev (Mint_token ()) in
    let owner = Big_map.find_opt 0n next.ledger in
    let () = Common.assert_success result in
    match owner with
        | Some _ -> ()
        | None -> Test.failwith "mitn token should address an owner"

let mint_token_owned_by_sender () = 
    let prev = Storage.empty in
    let sender = Tezos.get_sender () in
    let next, result = Common.transfer prev (Mint_token ()) in
    let owner = Big_map.find_opt 0n next.ledger |> Option.unopt in
    let () = assert (sender = owner) in
    Common.assert_success result

let mint_token_has_empty_operators () = 
    let prev = Storage.empty in
    let owner = Tezos.get_sender () in
    let next, result = Common.transfer prev (Mint_token ()) in
    let operators = Storage.get_operators owner 0n next in
    let () = assert (Set.size operators = 0n) in
    Common.assert_success result 


let test = 
    let () = mint_increments_counter () in
    let () = mint_add_metadata () in
    let () = mint_empty_token_info () in
    let () = mint_token_good_token_id () in
    let () = mint_token_has_owner () in
    let () = mint_token_owned_by_sender () in
    let () = mint_token_has_empty_operators () in
    ()
