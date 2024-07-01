#!/bin/bash

ADDRESS="0x5fbdb2315678afecb367f032d93f642f64180aa3"
BLOCK_NUMBER=3
HEX_BLOCK_NUMBER=$(printf "0x%x" $BLOCK_NUMBER)

API=http://127.0.0.1:8545

BLOCK=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["'"$HEX_BLOCK_NUMBER"'", true],"id":1}' -H "Content-Type: application/json" $API)

TRANSACTIONS=$(echo $BLOCK | jq -r '.result.transactions[] | select(.from == "'$ADDRESS'" or .to == "'$ADDRESS'")')

echo "Transactions involving $ADDRESS in block $BLOCK_NUMBER:"
echo $TRANSACTIONS
