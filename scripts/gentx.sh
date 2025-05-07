#!/bin/bash

# Accept node index as first argument or use INDEX env var, default to 0
INDEX=${1:-${INDEX:-0}}
AMOUNT=${2:-1000000000000000000000utest}

# Read moniker and mnemonic from nodes.json using the index
NODES_JSON="./config/nodes.json"
NODE_KEY=$(jq -r ".[$INDEX].name" "$NODES_JSON")
NODE_MNEMONIC=$(jq -r ".[$INDEX].mnemonic" "$NODES_JSON")

if [[ -z "$NODE_KEY" || "$NODE_KEY" == "null" ]]; then
  echo "[gentx.sh] Error: No node name found in $NODES_JSON at index $INDEX."
  exit 1
fi
if [[ -z "$NODE_MNEMONIC" || "$NODE_MNEMONIC" == "null" ]]; then
  echo "[gentx.sh] Error: No mnemonic found in $NODES_JSON at index $INDEX."
  exit 1
fi

BASEFEE=10000000

CHAINID=${CHAIN_ID:-cosmos_262144-1}
HOMEDIR="${HOME_DIR:-~/.evmd}"

KEYALGO="eth_secp256k1"
KEYRING="test"

echo "[gentx.sh] Recovering key for $NODE_KEY..."
echo "$NODE_MNEMONIC" | evmd keys add "$NODE_KEY" --recover --keyring-backend "$KEYRING" --algo "$KEYALGO"

echo "[gentx.sh] Generating gentx for $NODE_KEY with amount $AMOUNT..."
evmd genesis gentx "$NODE_KEY" "$AMOUNT" --gas-prices ${BASEFEE}utest --keyring-backend "$KEYRING" --chain-id "$CHAINID" --home "$HOMEDIR"

echo "[gentx.sh] gentx completed for $NODE_KEY (index $INDEX)"
