#import "./common.mligo" "Common"
#import "../storage.mligo" "Storage"
#import "../main.mligo" "Main"
#import "../entrypoints.mligo" "Entrypoints"
#import "../error.mligo" "Error"

let update_operators_owner_can_udpate () = 
    let _, token_id, prev = Common.Storage.with_token Storage.empty in
    let update_token: Entrypoints.Update_metadata.update_token = {token_id; metadata=Map.empty} in
    let update_metadata = Update_metadata [update_token] in
    let _ = Common.transfer prev update_metadata in
    ()

let update_operators_only_owner_can_update () = 
    let _, token_id, prev = Common.Storage.with_token Storage.empty in
    let update_token: Entrypoints.Update_metadata.update_token = {token_id; metadata=Map.empty} in
    let update_metadata = Update_metadata [update_token] in
    let () = Common.with_bob () in
    let (_, result) = Common.transfer_exn prev update_metadata in
    Common.assert_failwith result Error.fa2_not_owner


let test =
    let () = update_operators_owner_can_udpate () in
    let () = update_operators_only_owner_can_update () in
    ()
