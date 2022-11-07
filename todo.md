# MVP
 - readme
 - mail

# Roadmap


- docusaurus:
    - interactive documentation

- readme:
   - how to update a current nft contract
   - how to use
       - tezos-cli
       - off-chain
       - on-chain
    - tzip like

- off-chain: weather example
    - clean the code
    - get the block time from the rpc

- contract:
    - clean the code

- tests (only for the contract):
    - unit test
        - balance_of
        - update_operators
    - end to end

- Add metadata to NFT contract (TZIP-16)

- CI/CD:
    - compile
    - tests
    - Add secret key in github secret ?
    - deploy on Ghostnet

- contract feature:
    - add a way to protect fields
    - add a meta operator which can update the metadata of a token
    - view

- tests e2e:
    - weather example
    - check that token are properly updated
        - start the server and check
        - mint a new token
        - check a few moments later that temperature is set

- on-chain: example
   - need to find a good example
