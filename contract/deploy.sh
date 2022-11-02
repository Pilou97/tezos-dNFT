tezos-client --endpoint http://localhost:20000 originate contract nft transferring 0 from alice running "`cat nft.tz`" --init "`cat storage.tz`" --burn-cap 1 --force

sleep 4

tezos-client --endpoint http://localhost:20000 transfer 0 from alice to nft --arg "(Left (Left (Right Unit)))" --burn-cap 1

tezos-client --endpoint http://localhost:20000 show known contract nft