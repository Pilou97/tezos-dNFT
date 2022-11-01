#import "./common.mligo" "Common"
#import "../storage.mligo" "Storage"
#import "../main.mligo" "Main"
#import "../entrypoints.mligo" "Entrypoints"
#import "../error.mligo" "Error"

// Create a transfer transaction
let make_transfer (from_:address) (token_id: nat) (to_: address) (amount: nat) =
    let token_transfer = {
        to_;
        token_id;
        amount;
    } in
    let transfer_from = {
        from_;
        txs = [token_transfer]
    } in
    Transfer ([transfer_from])
    
let token_has_to_be_defined () = 
    let transfer = make_transfer Common.bob 123n Common.alice 1n in
    let _ , result = Common.transfer Storage.empty transfer in
    Common.assert_failwith result Error.fa2_token_undefined

let only_owner_can_transfer_token () = 
    let owner, token_id, storage = Common.Storage.with_token Storage.empty in
    let () = Common.with_bob () in
    let transfer = make_transfer owner token_id Common.alice 1n in
    let _, result = Common.transfer storage transfer in
    Common.assert_failwith result Error.fa2_not_operator // TODO: is it the correct error to throw ?

let cannot_transfer_amount_bigger_than_one () = 
    let owner, token_id, storage = Common.Storage.with_token Storage.empty in
    let transfer = make_transfer owner token_id Common.alice 2n in
    let _, result = Common.transfer storage transfer in
    Common.assert_failwith result Error.fa2_insufficient_balance

let test = 
    let () = token_has_to_be_defined () in
    let () = only_owner_can_transfer_token () in
    let () = cannot_transfer_amount_bigger_than_one () in
    ()

