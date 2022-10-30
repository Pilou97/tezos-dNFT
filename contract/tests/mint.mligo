#import "./common.mligo" "Common"
#import "../storage.mligo" "Storage"
#import "../main.mligo" "Main"

let mint_increments_counter () =
    let prev = Storage.empty in
    let next = Common.transfer prev (Mint_token ()) in
    let counter = next.counter in
    assert (counter = 1n)

let mint_add_metadata () = 
    let prev = Storage.empty in
    let previous_metadata = Big_map.mem 0n prev.token_metadata in
    let next = Common.transfer prev (Mint_token ()) in
    let next_metadata = Big_map.mem 0n next.token_metadata in
    let () = assert (previous_metadata = false) in
    assert (next_metadata = true)

let mint_empty_token_info () = 
    let prev = Storage.empty in
    let next = Common.transfer prev (Mint_token ()) in
    let token_metadata = Big_map.find_opt 0n next.token_metadata |> Option.unopt in
    let { token_id=_; token_info } = token_metadata in 
    let size = Map.size token_info in
    assert (size = 0n)

let mint_token_good_token_id () = 
    let prev = Storage.empty in
    let counter = prev.counter in
    let next = Common.transfer prev (Mint_token ()) in
    let token_metadata = Big_map.find_opt 0n next.token_metadata |> Option.unopt in
    let { token_id; token_info = _ } = token_metadata in 
    assert (counter = token_id)

let test = 
    let () = mint_increments_counter () in
    let () = mint_add_metadata () in
    let () = mint_empty_token_info () in
    let () = mint_token_good_token_id () in
    ()