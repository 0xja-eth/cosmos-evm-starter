#!/bin/bash

# Read JSON file
NODES_JSON="./config/nodes.json"

# Set Keyring and algorithm
KEYALGO="eth_secp256k1"
KEYRING="test"

# Read HOMEDIR environment variable
HOMEDIR="${HOME_DIR:-~/.evmd}"

# Get node count
NODE_COUNT=$(jq length "$NODES_JSON")
echo "[allocate.sh] $NODE_COUNT nodes found."

echo "[allocate.sh] Adding genesis accounts..."
# Loop through all nodes
for ((i=0; i<NODE_COUNT; i++)); do
  NODE_NAME=$(jq -r ".[$i].name" "$NODES_JSON")
  NODE_MNEMONIC=$(jq -r ".[$i].mnemonic" "$NODES_JSON")

  # Check if balance field exists and is not null
  NODE_BALANCE=$(jq -r ".[$i] | select(.balance != null) | .balance" "$NODES_JSON")
  if [[ -z "$NODE_BALANCE" ]]; then
    echo "[allocate.sh] Skipping node: $NODE_NAME (no balance field)"
    continue
  fi

  echo "[allocate.sh] Adding node: $NODE_NAME with balance: $NODE_BALANCE"
  # Create and add node to genesis file
  echo "$NODE_MNEMONIC" | evmd keys add "$NODE_NAME" --recover --keyring-backend "$KEYRING" --algo "$KEYALGO"
  evmd genesis add-genesis-account "$NODE_NAME" "$NODE_BALANCE" --keyring-backend "$KEYRING" --home "$HOMEDIR"

done

echo "[allocate.sh] All genesis accounts added successfully!"
