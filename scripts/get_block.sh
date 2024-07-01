#!/bin/bash

ADDRESS="0x7f1ed3d3aac8903f869eeb32182265dc34106353"
BLOCK_NUMBER=11697592
HEX_BLOCK_NUMBER=$(printf "0x%x" $BLOCK_NUMBER)
API=http://127.0.0.1:8545

BLOCK=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["'"$HEX_BLOCK_NUMBER"'", true],"id":1}' -H "Content-Type: application/json" $API)
TRANSACTIONS=$(echo $BLOCK | jq -r '.result.transactions[] | select(.from == "'$ADDRESS'" or .to == "'$ADDRESS'")')

echo "Transactions involving $ADDRESS in block $BLOCK_NUMBER:"
echo $TRANSACTIONS
