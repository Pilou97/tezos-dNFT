#import "./common.mligo" "Common"
#import "../storage.mligo" "Storage"
#import "../main.mligo" "Main"
#import "../entrypoints.mligo" "Entrypoints"

let update_operators_only_owner_can_udpate () = 
    let _, token_id, prev = Common.Storage.with_token Storage.empty in
    let update_token: Entrypoints.Update_metadata.update_token = {token_id; metadata=Map.empty} in
    let update_metadata = Update_metadata [update_token] in
    let _ = Common.transfer prev update_metadata in
    ()

let test =
    let () = update_operators_only_owner_can_udpate () in
    ()
