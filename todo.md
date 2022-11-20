# Roadmap

- off-chain: weather example
    - clean the code
    - tests e2e :
        - check that token are properly updated
            - start the server and check
            - mint a new token
            - check a few moments later that temperature is set
    - get the block time from the rpc => env var

- contract:
    - end to end tests 
    - add a way to protect fields
    - add a meta operator which can update the metadata of a token

- CI/CD:
    - get easily the contract address
    - initial storage to be compiled
    - fix flextesa version
    - add e2e tests when they exists
    - only deploy on push on main