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

let test = 
    let () = mint_increments_counter () in
    mint_add_metadata ()
