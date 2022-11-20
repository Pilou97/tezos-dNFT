# Roadmap

- off-chain: weather example
    - clean the code
    - tests e2e :
        - check that token are properly updated
            - start the server and check
            - mint a new token
            - check a few moments later that temperature is set
    - get the block time from the rpc

- contract:
    - clean the code
    - end to end tests
    - Add metadata to NFT contract (TZIP-16)
    - unit tests:
        - update_operators
        - balance_of
    - add a way to protect fields
    - add a meta operator which can update the metadata of a token
    - view
        - metadata

- CI/CD:
    - get easily the contract address
    - initial storage to be compiled
    - fix flextesa version
    - add e2e tests when they exists
    - only deploy on push on main

- on-chain: example
   - need to find a good example
   - readme