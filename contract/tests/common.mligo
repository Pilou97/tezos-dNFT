#import "../main.mligo" "Main"

// Util function to test a transfer
// TODO: maybe we don't need to originate a contract ??
let transfer storage entrypoint = 
    let addr, _, _ = Test.originate Main.main storage 0tez in
    let contract = Test.to_contract addr in
    let res = Test.transfer_to_contract contract entrypoint 1mutez in
    let storage = Test.get_storage addr in
    storage, res

let with_bob () = 
    let _ = Test.new_account () in
    let address = Test.nth_bootstrap_account 0 in
    Test.set_source address

let with_alice () = 
    let _ = Test.new_account () in
    let address = Test.nth_bootstrap_account 1 in
    Test.set_source address

let assert_failwith (result: test_exec_result) error = 
    match result with
        | Success _ -> Test.failwith "should fail"
        | Fail (Rejected (michelson_program, _))  ->
            let reason = Test.to_string michelson_program in
            let error = "\"" ^ error ^ "\"" in
            assert (reason = error)
        | Fail _ -> Test.failwith "should have failed with a different error"

let assert_success (result: test_exec_result) =
    match result with
        | Success _ -> ()
        | Fail _ -> Test.failwith "Should be a success"

module Storage = struct
    let with_token storage = 
        let owner = Tezos.get_sender () in
        let addr, _, _ = Test.originate Main.main storage 0tez in
        let contract = Test.to_contract addr in
        let _ = Test.transfer_to_contract_exn contract (Mint_token ()) 1mutez in
        let storage = Test.get_storage addr in
        (owner, 0n, storage)
end
