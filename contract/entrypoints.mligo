#import "storage.mligo" "Storage"
#import "error.mligo" "Error"

type return = operation list * Storage.t

module Transfer = struct
    type token_transfer = [@layout:comb]
    {
        to_: address;
        token_id: nat;
        amount: nat;
    }

    type transfer_from = {
        from_: address;
        txs: token_transfer list
    }

    type transfer = transfer_from list

    type t = transfer

    let transfer_from  (storage, {from_; txs}) =
        let {ledger; operators; token_metadata } = storage in
        let sender = Tezos.get_sender () in
        let transfer_one_token (ledger, {to_; token_id; amount}) = 
            let () = Storage.assert_token_defined token_id storage in
            let () = Storage.assert_can_transfer_token sender from_ token_id storage in
            let () = Storage.assert_sufficient_balance amount from_ token_id storage in
            let () = if amount > 1n then failwith Error.fa2_insufficient_balance else () in
            if amount = 0n then ledger 
            else Storage.transfer from_ to_ token_id ledger
        in
        let ledger = List.fold_left transfer_one_token ledger txs in
        {ledger; operators; token_metadata}

    let transition (transfer: transfer) (storage: Storage.t): return = 
        let storage = List.fold_left transfer_from storage transfer in
        ([], storage)
end 

module Balance_of = struct
    type request = {
        owner: address;
        token_id: nat;
    }

    type response = [@layout:comb] {
        request: request;
        balance: nat;
    }

    type balance_of = [@layout:comb] {
        requests: request list;
        callback: response list contract;
    }

    type t = balance_of

    let transition (balance_of: balance_of) (storage: Storage.t): return = 
        let {requests; callback} = balance_of in
            let responses = List.map (fun request ->
            let {owner; token_id} = request in
            let balance = Storage.get_balance owner token_id storage in
            { request; balance}
        ) requests in
        let operation = Tezos.transaction responses 0tez callback in
        ([operation], storage)
end

module Update_operators = struct
    type operator = [@layout:comb]
    {
        owner: address;
        operator: address;
        token_id: nat
    }

    type update_operator =
        | Add_operator of operator
        | Remove_operator of operator

    type update_operators = update_operator list

    type t = update_operators

    let transition (update_operators: update_operators) (storage: Storage.t): return = 
        let {ledger; operators; token_metadata} = storage in
        let update_operator (operators, operation) = match operation with
            | Add_operator {owner; operator; token_id} -> Storage.add_operator owner operator token_id operators
            | Remove_operator {owner; operator; token_id} -> Storage.remove_operator owner operator token_id operators
        in
        let operators = List.fold_left update_operator operators update_operators in
        let storage = {ledger; operators; token_metadata} in
        ([], storage)
end

module Update_metadata = struct
    type update = 
        | Update of bytes
        | Remove

    type update_token = {
        token_id: nat;
        metadata: (string, update) map  
    }

    type update_metadata = update_token list

    type t = update_metadata

    let update_token (storage, update_token: Storage.t * update_token): Storage.t = 
        // Some fields are reserved, so they can't be updated
        let {token_id; metadata} = update_token in
        if Map.mem "" metadata then failwith Error.fa2_reserved_metadata_field
        else if Map.mem "name" metadata then failwith Error.fa2_reserved_metadata_field
        else if Map.mem "symbol" metadata then failwith Error.fa2_reserved_metadata_field
        else if Map.mem "decimals" metadata then failwith Error.fa2_reserved_metadata_field
        else    

        // check if the token exists
        let token = Storage.get_token token_id storage in
        let token = match token with
            | None -> failwith Error.fa2_token_undefined
            | Some token -> token
        in

        let {token_id; token_info} = token in

        let update_one_field (acc, update) = 
            let (field, data) = update in
                match data with
                    | Update bytes -> Map.update field (Some bytes) acc
                    | Remove -> Map.update field None acc
            in
        let token_info = Map.fold update_one_field metadata token_info in
        let token = {token_id; token_info} in
        
        let storage = Storage.update_token token_id token storage in
        storage

    let transition (update_metadata: update_metadata) (storage: Storage.t): return = 
        let operations: operation list = [] in
        let storage = List.fold_left update_token storage update_metadata in
        operations, storage
end