alias ligo='docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.54.1'

ligo run test tests/mint.mligo
ligo run test tests/origination.mligo
ligo run test tests/transfer.mligo
ligo run test tests/update_metadata.mligo
ligo run test tests/update_operators.mligo