alias ligo='docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.54.1'

ligo run test contract/tests/mint.mligo
ligo run test contract/tests/origination.mligo
ligo run test contract/tests/transfer.mligo
ligo run test contract/tests/update_metadata.mligo
ligo run test contract/tests/update_operators.mligo