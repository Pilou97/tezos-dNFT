#import "./common.mligo" "Common"
#import "../entrypoints.mligo" "Entrypoints"
#import "../main.mligo" "Main"
#import "../storage.mligo" "Storage"
#import "../error.mligo" "Error"

let make_update_operator (owner: address) (operator: address) (token_id: nat) (add: bool) = 
    let operator= {
        owner=owner;
        operator=operator;
        token_id=token_id;
    } in
    let update_operator = if add then Add_operator operator else Remove_operator operator in
    Update_operators([update_operator])

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

let owner_can_add_operator () =
    let prev = Storage.empty () in
    let owner = Tezos.get_sender () in
    let prev_operators = Storage.get_operators owner 0n prev in
    let update_operator = make_update_operator owner Common.alice 0n True in
    let next, result = Common.transfer prev update_operator in
    let () = Common.assert_success result in
    let next_operators = Storage.get_operators owner 0n next in
    let () = assert (not (Set.mem Common.alice prev_operators)) in
    Test.assert (Set.mem Common.alice next_operators)

let owner_can_remove_operator () = 
    let prev = Storage.empty () in
    let owner = Tezos.get_sender () in
    let update_operator = make_update_operator owner Common.alice 0n True in
    let next, _ = Common.transfer prev update_operator in

    let update_operator = make_update_operator owner Common.alice 0n False in
    let next, result = Common.transfer next update_operator in
    let () = Common.assert_success result in
    let next_operators = Storage.get_operators owner 0n next in
    let () = Common.assert_success result in
    assert (not (Set.mem Common.alice next_operators))

let operator_cannot_add_operator () = 
    let prev = Storage.empty () in
    let sender = Tezos.get_sender () in
    let owner = Common.other sender in
    let update_operator = make_update_operator owner Common.alice 0n True in
    let _, result = Common.transfer prev update_operator in
    Common.assert_failwith result Error.fa2_not_owner

let operator_cannot_remove_operator () = 
    let prev = Storage.empty () in
    let sender = Tezos.get_sender () in
    let owner = Common.other sender in
    let update_operator = make_update_operator owner Common.alice 0n False in
    let _, result = Common.transfer prev update_operator in
    Common.assert_failwith result Error.fa2_not_owner

let operator_can_transfer_ticket () =
    let owner, token_id, previous = Common.Storage.with_token (Storage.empty ()) in
    let update_operator = make_update_operator owner Common.alice token_id True in
    let next, result = Common.transfer previous update_operator in
    let _ = Storage.get_operators owner token_id next in
    let () = Common.with_alice () in
    let transfer = make_transfer owner token_id Common.alice 1n in
    let _, _result = Common.transfer next transfer in
    Common.assert_success result

let test = 
    let () = owner_can_add_operator () in
    let () = owner_can_remove_operator () in
    let () = operator_cannot_add_operator () in
    let () = operator_cannot_remove_operator () in
    let () = operator_can_transfer_ticket () in
    ()