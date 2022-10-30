#import "storage.mligo" "Storage"
#include "entrypoints.mligo"

type return = operation list * Storage.t

type parameters = 
    // | Transfer of Transfer.t
    | Balance_of of Balance_of.t
    | Update_operators of Update_operators.t
    | Update_metadata of Update_metadata.t
    | Mint_token of Mint_token.t

let main (parameters, storage: parameters * Storage.t) : return = 
    match parameters with
        // | Transfer transfer -> Transfer.transition transfer storage
        | Balance_of balance_of -> Balance_of.transition balance_of storage
        | Update_operators update_operators -> Update_operators.transition update_operators storage
        | Update_metadata update_metadata -> Update_metadata.transition update_metadata storage 
        | Mint_token mint -> Mint_token.transition mint storage
