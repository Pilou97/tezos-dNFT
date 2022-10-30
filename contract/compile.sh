
rm -rf nft.tz
alias ligo='docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.54.1'
ligo compile contract main.mligo --protocol kathmandu --output-file nft.tz

# ligo compile storage main.mligo "`cat contract_storage.mligo`"