
rm -rf nft.tz
alias ligo='docker run --rm -v "$PWD":"$PWD" -w "$PWD" ligolang/ligo:0.53.0'
ligo compile contract main.mligo --output-file nft.tz