#!/usr/bin/bash

set -eE
trap cleanup_err ERR

FLEXTESA="http://localhost:20001"
CONTRACT_ADDRESS=""

function main() {
    fail
    check_requirements
    cd_to_workspace
    echo "Starting end to end tests"
    setup_tests

    cleanup
}

function cleanup() {
    trap - ERR
    set +e
    echo -n "[CLEANUP] removing flextesa instance... "
    docker stop e2e-flextesa
    docker rm e2e-flextesa
    echo "done"
}

function cleanup_err() {
    cleanup
    exit 1
}

function check_requirements {
    docker-compose version > /dev/null
    ligo --version > /dev/null
    octez-client --version > /dev/null || tezos-client --version > /dev/null
    jq --version
}

function cd_to_workspace() {
    cd "$(dirname "$0")"
    cd ..
}

function setup_tests() {
    echo -n "starting flextesa instance... "
    docker run --name "e2e-flextesa" -d -e "block_time=3" -p 20001:20000 oxheadalpha/flextesa:latest kathmandubox start
    sleep 10
    echo "done"
    compile_contract
    deploy_contract
    mint_token
    run_weather_app
}

function compile_contract() {
    cd contract
    ./compile.sh
    cd ..
}

function deploy_contract() {
    cd contract
    ./deploy.sh 20001
    sleep 3
    CONTRACT_ADDRESS="$(octez-client --endpoint $FLEXTESA show known contract nft | grep KT1 | tr -d '\r')" ||
    CONTRACT_ADDRESS="$(tezos-client --endpoint $FLEXTESA show known contract nft | grep KT1 | tr -d '\r')"
    cd ..
}

function mint_token() {
    cd contract
    tezos-client --endpoint $FLEXTESA transfer 0 from alice to nft --arg '(Left (Left (Right { Elt "latitude" 0x0304990A ; Elt "longitude" 0x002EAB94 })))' --burn-cap 1 ||
    octez-client --endpoint $FLEXTESA transfer 0 from alice to nft --arg '(Left (Left (Right { Elt "latitude" 0x0304990A ; Elt "longitude" 0x002EAB94 })))' --burn-cap 1
    cd ..
}

function run_weather_app() {
    cd offchain
    TEZOS_ENDPOINT=$FLEXTESA CONTRACT=$CONTRACT_ADDRESS npm run start& > /dev/null
    sleep 3
    cd ..
}

function assert_temperature_updated() {
    tezos-client --endpoint $FLEXTESA show known contract nft
    # rebase on dev
    # redeploy
    tezos-client --endpoint get contract storage for nft
}
curl http://localhost:20000/chains/main/blocks/head/context/big_maps/6
main