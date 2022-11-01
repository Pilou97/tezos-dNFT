#import "./common.mligo" "Common"
#import "../storage.mligo" "Storage"
#import "../main.mligo" "Main"
#import "../entrypoints.mligo" "Entrypoints"
#import "../error.mligo" "Error"

let update_operators_owner_can_udpate () = 
    let _, token_id, prev = Common.Storage.with_token Storage.empty in
    let update_token: Entrypoints.Update_metadata.update_token = {token_id; metadata=Map.empty} in
    let update_metadata = Update_metadata [update_token] in
    let _, result = Common.transfer prev update_metadata in
    Common.assert_success result

let update_operators_only_owner_can_update () = 
    let _, token_id, prev = Common.Storage.with_token Storage.empty in
    let update_token: Entrypoints.Update_metadata.update_token = {token_id; metadata=Map.empty} in
    let update_metadata = Update_metadata [update_token] in
    let () = Common.with_bob () in
    let _, result = Common.transfer prev update_metadata in
    Common.assert_failwith result Error.fa2_not_owner

let cannot_update_reserved_field field =
    let bytes = Bytes.pack 0 in
    let update : Entrypoints.Update_metadata.update = (Update bytes) in
    let metadata = Map.empty |> Map.add field update in
    let _, token_id, prev = Common.Storage.with_token Storage.empty in
    let update_token: Entrypoints.Update_metadata.update_token = {token_id; metadata} in
    let update_metadata = Update_metadata [update_token] in
    let _, result = Common.transfer prev update_metadata in
    Common.assert_failwith result Error.fa2_reserved_metadata_field 

let cannot_update_reserved_empty () = cannot_update_reserved_field ""

let cannot_update_reserved_name () = cannot_update_reserved_field "name"

let cannot_update_reserved_symbol () = cannot_update_reserved_field "symbol"

let cannot_update_reserved_decimals () = cannot_update_reserved_field "decimals"

let add_new_field () = 
    let field = "new-field" in
    let one = Bytes.pack 0 in
    let update : Entrypoints.Update_metadata.update = (Update one) in
    let metadata = Map.empty |> Map.add field update in
    let _, token_id, prev = Common.Storage.with_token Storage.empty in
    let update_token: Entrypoints.Update_metadata.update_token = {token_id; metadata} in
    let update_metadata = Update_metadata [update_token] in
    let storage, result = Common.transfer prev update_metadata in

    let token_metadata = storage.token_metadata |> Big_map.find_opt token_id |> Option.unopt in
    let {token_id=_; token_info} = token_metadata in
    let value = Map.find_opt "new-field" token_info in
    let () = Common.assert_success result in
    match value with
        | None -> Test.failwith "Metadata should be set"
        | Some value -> assert (value = one)

let update_existing_field () = 
    let field = "new-field" in
    let one = Bytes.pack 0 in

    let update : Entrypoints.Update_metadata.update = (Update one) in
    let metadata = Map.empty |> Map.add field update in
    let _, token_id, prev = Common.Storage.with_token Storage.empty in
    let update_token: Entrypoints.Update_metadata.update_token = {token_id; metadata} in
    let update_metadata = Update_metadata [update_token] in
    let prev, _ = Common.transfer prev update_metadata in

    let two = Bytes.pack 1 in
    let update : Entrypoints.Update_metadata.update = (Update two) in
    let metadata = Map.empty |> Map.add field update in
    let update_token: Entrypoints.Update_metadata.update_token = {token_id; metadata} in
    let update_metadata = Update_metadata [update_token] in
    let storage, result = Common.transfer prev update_metadata in

    let token_metadata = storage.token_metadata |> Big_map.find_opt token_id |> Option.unopt in
    let {token_id=_; token_info} = token_metadata in
    let value = Map.find_opt "new-field" token_info in
    let () = Common.assert_success result in
    match value with
        | None -> failwith "Metadata should be set"
        | Some value -> assert (value = two)

// Remove a non existing field: TODO: rename the test
let remove_field () = 
    let field = "to-remove" in
    let update : Entrypoints.Update_metadata.update = Remove in
    let _, token_id, prev = Common.Storage.with_token Storage.empty in
    let metadata = Map.empty |> Map.add field update in
    let update_token: Entrypoints.Update_metadata.update_token = {token_id; metadata} in
    let update_metadata = Update_metadata [update_token] in
    let _, result = Common.transfer prev update_metadata in
    Common.assert_success result

let remove_existing_field () = 
    let field = "to-remove" in
    let one = Bytes.pack 0 in
    let update : Entrypoints.Update_metadata.update = (Update one) in
    let metadata = Map.empty |> Map.add field update in
    let _, token_id, prev = Common.Storage.with_token Storage.empty in
    let update_token: Entrypoints.Update_metadata.update_token = {token_id; metadata} in
    let update_metadata = Update_metadata [update_token] in
    let prev, _ = Common.transfer prev update_metadata in

    let update : Entrypoints.Update_metadata.update = Remove in
    let metadata = Map.empty |> Map.add field update in
    let update_token: Entrypoints.Update_metadata.update_token = {token_id; metadata} in
    let update_metadata = Update_metadata [update_token] in
    let storage, result = Common.transfer prev update_metadata in

    let token_metadata = storage.token_metadata |> Big_map.find_opt token_id |> Option.unopt in
    let {token_id=_; token_info} = token_metadata in
    let value = Map.find_opt field token_info in
    let () = Common.assert_success result in
    match value with
        | Some _ ->failwith "the field should has been removed"
        | None -> ()

let test =
    let () = update_operators_owner_can_udpate () in
    let () = update_operators_only_owner_can_update () in
    let () = cannot_update_reserved_empty () in
    let () = cannot_update_reserved_name () in
    let () = cannot_update_reserved_symbol () in
    let () = cannot_update_reserved_decimals () in
    let () = add_new_field () in
    let () = update_existing_field () in
    let () = remove_field () in
    let () = remove_existing_field () in
    ()
