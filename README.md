# tezos-dNFT

# Roadmap
## Setup
- docker compose setup flextesa
   - https://gitlab.com/tezos/flextesa
   - script: kathmandou
- install tezos-cli
   - https://opentezos.com/tezos-basics/cli-and-rpc/
- install ligo with docker
- transaction with tezos-cli
- counter example
  `ligo compile contract counter.mligo > output.tz`
  `ligo compile storage counter.mligo "{counter = 0n}"`

## MVP:
- read the TZIP-12
   - https://gitlab.com/tezos/tzip/-/blob/master/proposals/tzip-12/tzip-12.md
   - see section "Token Balance Updates" "NFT asset contract" for NFT specification

- Reimplement an NFT contract
   - https://github.com/ligolang/NFT-factory-cameligo
   - storage should be `map nat address` (cf above)
   - defined custom entrypoint (so that we can start making example)
        - update_metadata

- off-chain: weather example: create a backend in any language
   - typescript is simpler (because we will be able to use Taquito)
   - pull a weather api each 30 seconds (best way => for each tezos block)
   - send the transaction to a dNFT contract

- on-chain: example
   - need to find a good example

- create a documentation: README.md
   - how to update a current nft contract
   - how to use
       - tezos-cli
       - off-chain
       - on-chain

## Bonus:
 - tests
 - deployed on Ghostnet
 - CI/CD => auto deploy
 - docusaurus documentation with wallet integration
 - Add a second entrypoint to the contract:
     - update-meta-operators: so that several addresses can update the metadata of an NFT
     - another example based on a real life asset

 - implement FA1.2
 - event ?

# Tezos dNFT
TODO: add description of the project, quote the bounty

## Requirements:
 - ligo 0.54.1 
 - tezos-client (tested with 4ca33194)

## How to compile:

TODO: explain the comand

```bash
ligo compile contract contract/main.mligo --protocol kathmandu --output-file nft.tz
```


## How to originate:

TODO: explain the comand, explain the storage

```bash
storage="(Pair (Pair 0 {}) {} {})"
tezos-client originate contract dNFT transferring 0 from alice running "`cat nft.tz`" --init "$storage" --burn-cap 1 --force
```

## How to use:
TODO: indicates how to add metadata, remove metadata, update metadata

## How to transform your NFT to a dNFT
TODO: explain the code and what to add in an existing ligo nft code

## Tests:

TODO: explain the test strategy

```bash
ligo run test contract/tests/origination.mligo
ligo run test contract/tests/mint.mligo
ligo run test contract/tests/update_metadata.mligo
```
TODO: add some code coverage ??

# Authors:
- Pierre-Louis Dubois
- Pierre-Jean Sauvage