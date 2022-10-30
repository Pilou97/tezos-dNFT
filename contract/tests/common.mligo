#import "../main.mligo" "Main"

// Util function to test a transfer
let transfer storage entrypoint = 
    let addr, _, _ = Test.originate Main.main storage 0tez in
    let contract = Test.to_contract addr in
    let _ = Test.transfer_to_contract_exn contract entrypoint 1mutez in
    Test.get_storage addr