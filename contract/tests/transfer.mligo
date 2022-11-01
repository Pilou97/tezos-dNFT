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


let test = 
    let () = token_has_to_be_defined () in
    ()

