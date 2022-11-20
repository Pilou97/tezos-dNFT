# Dynamic NFTs (dNFTs) on Tezos

This project is a small demonstration of how you can use dynamic NFTs (dNFT) on Tezos.
It consists of a generic smart contract which implements [tzip-12](https://gitlab.com/tezos/tzip/-/blob/master/proposals/tzip-12/tzip-12.md).

We added one entry point to the contract `update_metadata` to allow the owner of a token to update the metadata of a token.
We are providing the specification of the new entrypoint.

To show how this contract is working we've made an example which consists of storing NFTs which hold GPS coordinates and temperature.
The temperature is then updated at each new block (if needed) by an off-chain server using [Taquito](https://tezostaquito.io/).

## Bounty statement
 > **Dynamic NFTs (dNFTs) on Tezos**
 > Create an extensive code template on how to create a dynamic NFT (dNFT) on Tezos. A dNFT is a
 > non-fungible token whose metadata can be updated based on external conditions that originate either
 > off-chain (e.g., blockchain oracle data) or on-chain (e.g., transaction statistics).

## Requirements:
 - linux based OS
 - ligo 0.54.1
 - octez-client 8408476f v15.0
 - node 18
 - npm 8.19.2
 - docker (for tests)
 - docker compose version 2.1.12 (for dev environment)
 - jq (for tests)
 - curl (for tests)

## Tested on
- tested ubuntu 22.04 x86_64 and Linux 6.0.6-arch1-1 x86_64
- ligo 0.54.1
- octez-client (tested with 8408476f v15.0)
- docker 20.10.21
- docker compose version 2.1.12
- node 18
- npm 8.19.2

## Quickstart

To run quickly this project, you can run the following commands :

```bash
docker-compose up -d # run a development flextesa instance
scripts/deploy.sh # compile and deploy a smart contract with 2 initial NFT
cd offchain
npm i
CONTRACT=$(octez-client --endpoint http://localhost:20000 show known contract nft | grep KT1 | tr -d '\r') npm run start # run the offchain example (weather application)
```

You will see your tokens and their associated metadata. The tokens metadata represent the location of [Null Island](https://en.wikipedia.org/wiki/Null_Island) and [Lille](https://en.wikipedia.org/wiki/Lille).
The weather application will update in real time the temperature of the different locations.
When a new temperature is found, an operation will be submitted to the smart contract to update the different metadata.
You should see a log like:

```
[
  { key: '0', latitude: 50.63297, longitude: 3.05858, temperature: 9 },
  { key: '1', latitude: 0.000001, longitude: 0.000002, temperature: 26}
]
```

You can find more detailed instructions below.

## How to compile:

We are using [ligo](https://ligolang.org) as the contract language (with the cameligo syntax). You can refer to the [ligo documentation](https://ligolang.org/docs/manpages/compile%20contract) to compile a contract.
Or use the following command. We are using `--protocol kathmandu` due to a warning/advice of the ligo compiler.

```bash
ligo compile contract contract/main.mligo --protocol kathmandu --output-file nft.tz
```

### How to run the tests:

We decided to add some integration tests. With the ligo test framework we can tests the different entry points of our smart contract.

We provide a bash script to run these tests (it will use docker to run ligo):
```
scripts/test.sh
```

Or you can run the tests individually:

```bash
ligo run test contract/tests/origination.mligo
ligo run test contract/tests/mint.mligo
ligo run test contract/tests/update_metadata.mligo
ligo run test contract/tests/transfer.mligo
ligo run test contract/tests/update_operators.mligo
```

## How to use

### How to originate:



### Running in a development environment

During development, we used [flextesa](https://gitlab.com/tezos/flextesa) to deploy the contract.
You can run your own flextesa chain by running the docker-compose in this repo :

```bash
docker-compose up -d
```
It will start a flextesa instance listening on `localhost:20000` with a new block
every 3 seconds.

In our commands, we are using a local flextesa. If you want to originate on
Ghostnet or Mainnet, please adapt the endpoint argument.

### Originate

You can originate this the contract on the mainnet (but you have to have some tez), or on the Ghostnet. You can also originate on a development flextesas instance.

To originate the contract, we need a storage. We originate the contract with an
empty storage, as it's more convenient.

```bash
storage='(Pair (Pair (Pair 0 {}) { Elt "" 0x68747470733a2f2f63656c6c61722d63322e73657276696365732e636c657665722d636c6f75642e636f6d2f6d657461646174612f646e66742e6a736f6e } {}) {})'
octez-client --endpoint http://localhost:20000 originate contract nft transferring 0 from alice running "`cat nft.tz`" --init "$storage" --burn-cap 1 --force
```

### Mint

Let's mint a token which will hold the temperature of a city.
The following command will mint a token with a metadata field called "temperature", the value should be a byte encoded in an hex string. Here 20 degrees (Celsius), or 0x14 in hexadecimal.
```
parameter='(Left (Left (Right { Elt "temperature" 0x14 ; })))'
octez-client --endpoint http://localhost:20000 transfer 0 from alice to nft --arg $parameter --burn-cap 1
```
We can check that metadata have been updated by fetching the big map containing the token metadata.

```
big_map=$(octez-client --endpoint http://localhost:20000 get contract storage for nft |  cut -d" " -f 8) # To retrieve the id of the big map containing the metadata of the token
curl http://localhost:20000/chains/main/blocks/head/context/big_maps/$big_map
```

### Update metadata

We can update manually the metadata to set a new temperature.
Let's change it to 21 degrees (0x15 in hexadecimal).

```
parameter='(Left (Right (Right { Pair { Elt "temperature" (Right 0x15) } 0 })))'
octez-client --endpoint http://localhost:20000 transfer 0 from alice to nft --burn-cap 1 --fee-cap 1 --arg $parameter
```

Again, we can check that the metadata changed with the following command :
```
big_map=$(octez-client --endpoint http://localhost:20000 get contract storage for nft |  cut -d" " -f 8)
curl http://localhost:20000/chains/main/blocks/head/context/big_maps/$big_map
```

### Add a new field

If the field doesn't exist in the nft metadata, the given fields will be added.
Here we decided to add the location as latitude/longitude coordinates.

```
parameter='(Left (Right (Right { Pair { Elt "latitude" (Right 0x0304990A) ; Elt "longitude" (Right 0x002EAB94) } 0 })))'
octez-client --endpoint http://localhost:20000 transfer 0 from alice to nft --burn-cap 1 --fee-cap 1 --arg $parameter
```

### Remove

If you made a mistake and want to remove a field from the token metadata, you can.
In our example we decided to remove the temperature.

```
parameter='(Left (Right (Right { Pair { Elt "temperature" (Left Unit) } 0 })))'
octez-client --endpoint http://localhost:20000 transfer 0 from alice to nft --burn-cap 1 --fee-cap 1 --arg $parameter
```

## Specification of a dNFT

### Interface specification

This interface is an increment to the already existing [tzip-12](https://gitlab.com/tezos/tzip/-/blob/master/proposals/tzip-12/tzip-12.md)

The contract MUST have the following entrypoint: `update_metadata`;

### Entrypoint Semantics

```
(list %update_metadata
   (pair
      (map %metadata
         string
         (or (unit %remove) (bytes %update))
      )
      (nat %token_id)
   )
)
```

Each metadata update in the batch is a pair with the id of the token (`token_id`) and the metadata to update (`metadata`).
You can either update or remove a metadata for a given token_id.

### Update metadata behavior

Update metadata MUST always implement this behavior

 - Every metadata update MUST happen atomically and in order. If at least one metadata in the batch cannot be completed, the whole transaction MUST fail, all metadata updates MUST be reverted, and token metadata MUST remain unchanged
 - If one of the specified `token_id` is not defined within the FA2 contract, the entrypoint MUST fail with the error mnemonic `"FA2_TOKEN_UNDEFINED"`
 - Metadata update of no provided metadata MUST be treated as normal metadata update
 - Each update of metadata MUST only update the appropriate field of the given `token_id`
 - Each remove of metadata MUST only remove the appropriate field of the given `token_id`
 - Removing a non existing field MUST not change the token metadata
 - Updating a non existing field MUST add the new field with the corresponding value to the metadata of the given `token_id`
 - You can't update/remove reserved field of the metadata: `""`, `"name"`, `"symbol"`, `"decimals"`

### Default Update Permission Policy

 - Token owner address SHOULD be able to perform metadata updates of its own tokens

## Offchain example

To demonstrate the use of dNFTs, we made a simple offchain application that checks
the temperature of different locations.

The application is pretty straight forward : every block, we check the temperature
for every locations listed in the smart contract. If one of the temperature changed,
we update the contract to commit that change.

### Requirements:
Be sure to check that the requirements are met for node and npm for this part.

### Configuration

The offchain program has a few configurable values that are situated in `/offchain/config`:
```json
{
    "tezosEndpoint": "http://localhost:20000",
    "blockTime": 3000,
    "signer": "edsk3QoqBuvdamxouPhin7swCvkQNgq4jP5KZPbwWNnwdZpSpJiEbq",
    "contract": ""
}
```

- `tezosEnpoint` corresponds to the node you want to query. It defaults to
`http://localhost:20000` so that you can easily use the offchain program with a
local flextesa instance.

-  `blockTime` corresponds to the time in milliseconds between two attemps to update
the contract. This means that you want to set this value to the block duration of the
desired chain. This value should be set to 30000 on the Mainnet or the Ghostnet.
It defaults to 3000 to match with the development flextesa instance.

- `signer` is the tezos private key that will be used to sign transactions on the
chain. The default value corresponds to the default user set on a flextesa instance.

- `contract` is the contract address. Its value is empty by default, because we
instanciate a new contract every time we launch a new flextesa instance. To know the
contract address, you need to originate the contract. See
[How to originate](#how-to-originate). If you already originated a contract, you
can retrieve its address with
```bash
octez-client --endpoint http://localhost:20000 show known contract nft
```

### Run the offchain example

We suppose that we are running the example against a local flextesa instance and that we have originated and minted a token as described earlier.

The first step is to install all the dependencies of the application :
```
cd offchain
npm install
```

To run the offchain example, we simply have to launch npm run start with the
address of the contract we originated on the flextesa instance.

```
CONTRACT=$(octez-client --endpoint http://localhost:20000 show known contract nft | grep KT1 | tr -d '\r') npm run start
```

### End to end tests

We provide end to end tests:

```
tests/run-tests.sh
```

## Github actions


We set up some jobs in the github actions to compile, tests, and deploy (on ghostnet)
our contract on each update on the main branch.

# Authors:
- Pierre-Louis Dubois
- Pierre-Jean Sauvage