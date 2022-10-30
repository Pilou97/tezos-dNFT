#import "./common.mligo" "Common"
#import "../storage.mligo" "Storage"
#import "../main.mligo" "Main"

let mint_increments_counter () =
    let prev = Storage.empty in
    let next = Common.transfer prev (Mint_token ()) in
    let counter = next.counter in
    assert (counter = 1n)

let test = 
    mint_increments_counter ()
