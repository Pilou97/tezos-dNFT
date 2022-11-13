# Roadmap

- docusaurus:
    - interactive documentation

- off-chain: weather example
    - clean the code
    - get the block time from the rpc
    - tests e2e :
        - check that token are properly updated
            - start the server and check
            - mint a new token
            - check a few moments later that temperature is set

- contract:
    - clean the code
    - end to end tests 
    - unit tests:
        - update_operators
        - balance_of
    - view
        - metadata
    - Add metadata to NFT contract (TZIP-16)
    - add a way to protect fields
    - add a meta operator which can update the metadata of a token

- CI/CD:
    - compile
    - tests
    - Add secret key in github secret ?
    - deploy on Ghostnet

- on-chain: example
   - need to find a good example
   - readme 