#import "../main.mligo" "Main"

// Util function to test a transfer
// TODO: maybe we don't need to originate a contract ??
let transfer storage entrypoint = 
    let addr, _, _ = Test.originate Main.main storage 0tez in
    let contract = Test.to_contract addr in
    let _ = Test.transfer_to_contract_exn contract entrypoint 1mutez in
    Test.get_storage addr

module Storage = struct
    let with_token storage = 
        let owner = Tezos.get_sender () in
        let addr, _, _ = Test.originate Main.main storage 0tez in
        let contract = Test.to_contract addr in
        let _ = Test.transfer_to_contract_exn contract (Mint_token ()) 1mutez in
        let storage = Test.get_storage addr in
        (owner, 0n, storage)
end