#!/usr/bin/bash

set -e

if [[ -z $1 ]]; then
    PORT=20000
else
    PORT=$1
fi

function ligo(){
  docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.54.1 "$@"
}

contract=$(ligo compile contract contract/main.mligo)
storage=$(ligo compile storage contract/main.mligo "Storage.empty ()")

octez-client --endpoint http://localhost:$PORT originate contract nft transferring 0 from alice running "$contract" --init "$storage" --burn-cap 1 --force
sleep 4

octez-client --endpoint http://localhost:$PORT transfer 0 from alice to nft --arg '(Left (Left (Right { Elt "latitude" 0x0304990A ; Elt "longitude" 0x002EAB94 })))' --burn-cap 1

octez-client --endpoint http://localhost:$PORT transfer 0 from alice to nft --arg '(Left (Left (Right { Elt "latitude" 0x00 ; Elt "longitude" 0x00 })))' --burn-cap 1

octez-client --endpoint http://localhost:$PORT show known contract nft