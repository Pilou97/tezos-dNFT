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
 - ligo 0.54.1
 - tezos-client (tested with 4ca33194)
 - docker compose version 2.1.12 (only for dev purpose)


## How to compile:

We are using ligo as the contract language. You can refer to the [ligo documentation](https://ligolang.org/docs/manpages/compile%20contract) to compile a contract.
Or use the following command. We are using `--protocol kathmandu` due to a warning/advice of the ligo compiler.

```bash
ligo compile contract contract/main.mligo --protocol kathmandu --output-file nft.tz
```

### How to run the tests:

We decided to add some integration tests. With the ligo test framework we can tests the different entry points of our smart contract.

```bash
ligo run test contract/tests/origination.mligo
ligo run test contract/tests/mint.mligo
ligo run test contract/tests/update_metadata.mligo
ligo run test contract/tests/transfer.mligo
```

## How to use

### How to originate:

You can either originate this the contract on the mainnet (but you have to have some tez). Or your can originate this contract on the Ghostnet.

### Running in a development environment

During development, we used [flextesa](https://gitlab.com/tezos/flextesa) to deploy the contract.
You can run your own flextesa chain by running the docker-compose in this repo :

```bash
docker-compose up
```
It will start a flextesa instance listening on localhost:20000 with a new block
every 3 seconds.

In our commands, we are using a local flextesa. If you want to originate on
Ghostnet or Mainnet, please adapt the endpoint argument.

### Originate

First you need to have a storage. At the beginning our contract will be empty,
it's more convenient.

```bash
storage="(Pair (Pair 0 {}) {} {})"
tezos-client originate contract dNFT transferring 0 from alice running "`cat nft.tz`" --init "$storage" --burn-cap 1 --force
```

### Mint

Let's mint a token which will hold the temperature of a city.
The following command will mint a token with a metadata field called "temperature", the value should be a byte, here 20 degrees (0x14 in hexadecimal).
```
tezos-client --endpoint http://localhost:20000 transfer 0 from alice to nft --arg '(Left (Left (Right { Elt "temperature" 0x14 ; })))' --burn-cap 1
```

### Update metadata

We can update manually the metadata to set a new temperature.
Let's say 21 degrees which is 0x15 in hexadecimal.

```
SCRIPT='(Left (Right (Right { Pair { Elt "temperature" (Right 0x15) } 0 })))'
tezos-client --endpoint http://localhost:20000 transfer 0 from alice to nft --burn-cap 1 --fee-cap 1 --arg $SCRIPT
```

### Add a new field

If the field doesn't exist in the nft metadata, the given fields will be added.
Here we decided to add the location as latitude/longitude coordinates.

```
SCRIPT='(Left (Right (Right { Pair { Elt "latitude" 0x0304990A ; Elt "longitude" 0x002EAB94 } 0 })))'
tezos-client --endpoint http://localhost:20000 transfer 0 from alice to nft --burn-cap 1 --fee-cap 1 --arg $SCRIPT
```

### Remove

If you made a mistake and want to remove a field from the token metadata, you can.
In our example we decided to remove the temperature.

```
SCRIPT='(Left (Right (Right { Pair { Elt "temperature" (Left Unit) } 0 })))'
tezos-client --endpoint http://localhost:20000 transfer 0 from alice to nft --burn-cap 1 --fee-cap 1 --arg $SCRIPT
```

## How to transform your NFT to a dNFT

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

Each metadata update in the bach as a pair with the `token_id` and the metadata to update `metadata`.
You an either update or remove a metadata for a given token_id.

### Update metadata behavior

Update metadata MUST always implement this behavior

 - Every metadata update MUST happen atomically and in order. If at least one metadata in the batch cannot be completed, the whole transaction MUST fail, all metadata updates MUST be reverted, and token metadatas MUST remain unchanged
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
 - node 18
 - npm 8.19.2

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

`tezosEnpoint` corresponds to the node you want to query. It defaults to
`http://localhost:20000` so that you can easily use the offchain program with a
local flextesa instance.

`blockTime` corresponds to the time in milliseconds between two attemps to update
the contract. This means that you want to set this value to the block duration of the
wanted chain. This value should be set to 30000 on the Mainnet or the Ghostnet.
It defaults to 3000 to match with the development flextesa instance.

`signer` is the tezos private key that will be used to sign transactions on the
chain. The default value corresponds to the default user set on a flextesa instance.

`contract` is the contract address. Its value is empty by default, because we instanciate
a new contract every time we launch a new flextesa instance. To know the contract
address, you need to originate the contract. See [How to originate](#how-to-originate)
see how to do so.

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
CONTRACT=$(tezos-client --endpoint http://localhost:20000 show known contract nft | grep KT1 | tr -d '\r') npm run start
```

# Authors:
- Pierre-Louis Dubois
- Pierre-Jean Sauvage