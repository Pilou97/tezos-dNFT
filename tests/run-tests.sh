#!/usr/bin/bash

set -eE
trap cleanup_err ERR

FLEXTESA="http://localhost:20001"
CONTRACT_ADDRESS=""
export TEZOS_CLIENT_UNSAFE_DISABLE_DISCLAIMER=yes

function main() {
    check_requirements
    cd_to_workspace
    setup_tests
    run_tests

    cleanup
}

function cleanup() {
    trap - ERR
    set +e

    echo "===== Tests cleanup ====="
    echo -n "[CLEANUP] removing flextesa instance... "
    docker stop e2e-flextesa > /dev/null
    docker rm e2e-flextesa > /dev/null
    echo "done"
}

function cleanup_err() {
    echo ""
    echo "test failed"
    cleanup
    exit 1
}

function check_requirements {
    echo -n "Check requirements... "
    docker-compose version > /dev/null
    ligo --version > /dev/null
    octez-client --version > /dev/null
    jq --version > /dev/null
    echo "OK"
}

function cd_to_workspace() {
    cd "$(dirname "$0")"
    cd ..
}

function setup_tests() {
    echo "====== Tests setup ======"
    start_flextesa
    deploy_contract
    mint_token
    run_weather_app
    echo "=== Tests setup done  ==="
    echo ""
}

function start_flextesa() {
    echo -n "starting flextesa instance... "
    docker run --name "e2e-flextesa" -d -e "block_time=3" -p 20001:20000 oxheadalpha/flextesa:latest kathmandubox start > /dev/null
    sleep 10
    echo "done"
}

function deploy_contract() {
    echo -n "Deploying contract... "
    scripts/deploy.sh 20001 > /dev/null 2> /dev/null
    sleep 3
    CONTRACT_ADDRESS="$(octez-client --endpoint $FLEXTESA show known contract nft 2> /dev/null | grep KT1 | tr -d '\r')"
    echo "done"
}

function mint_token() {
    echo -n "Minting nft... "
    octez-client --endpoint $FLEXTESA transfer 0 from alice to nft --arg '(Left (Left (Right { Elt "latitude" 0x0304990A ; Elt "longitude" 0x002EAB94 })))' --burn-cap 1 1> /dev/null 2> /dev/null
    echo "done"
}

function run_weather_app() {
    echo -n "Starting up offchain app..."
    cd offchain
    TEZOS_ENDPOINT=$FLEXTESA CONTRACT=$CONTRACT_ADDRESS npm run start 1> /dev/null 2> /dev/null &
    sleep 3
    cd ..
    echo "done"
}

function run_tests() {
    echo "==== Running tests ===="
    assert_temperature_updated
    echo "=== Tests run done  ==="
    echo ""
    echo "All tests were successful"
    echo ""

}

function assert_temperature_updated() {
    echo -n "Running test : ${FUNCNAME[0]}... "
    octez-client --endpoint $FLEXTESA show known contract nft > /dev/null 2> /dev/null
    big_map=$(octez-client --endpoint get contract storage for nft 2> /dev/null | cut -d" " -f 8)
    value=$(curl $FLEXTESA/chains/main/blocks/head/context/big_maps/$big_map 2> /dev/null | jq -r ".[0].args[1][2].args[1].bytes")
    [[ "$value" != "null" ]]
    echo "test success"
}

main