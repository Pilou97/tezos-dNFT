#import "../storage.mligo" "Storage"
#import "../main.mligo" "Main"

let origination () =
    let taddr, _, _ = Test.originate Main.main (Storage.empty ()) 0tez in
    assert (Test.get_storage taddr = Storage.empty ())

let test = 
    let () = origination () in
    ()