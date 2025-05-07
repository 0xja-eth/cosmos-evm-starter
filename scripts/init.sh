#!/bin/bash

# Accept node index as first argument or use INDEX env var, default to 0
INDEX=${1:-${INDEX:-0}}
PENDING=${2:-${PENDING:-false}}

# Read moniker from nodes.json using the index
NODES_JSON="./config/nodes.json"
MONIKER=$(jq -r ".[$INDEX].name" "$NODES_JSON")

if [[ -z "$MONIKER" || "$MONIKER" == "null" ]]; then
  echo "[init.sh] Error: No node name found in $NODES_JSON at index $INDEX."
  exit 1
fi

CHAINID=${CHAIN_ID:-cosmos_262144-1}
# Read HOME_DIR environment variable
HOMEDIR="${HOME_DIR:-~/.evmd}"

echo "[init.sh] Start node initialization for node#$INDEX $MONIKER, chain id: $CHAINID, home directory: $HOMEDIR"
evmd init $MONIKER -o --chain-id "$CHAINID" --home "$HOMEDIR"

echo "[init.sh] Setting config file paths..."
# In addition to a simple init operation, we also need to modify the generated config files:

# Define paths for various config files, will be modified to start the blockchain
CONFIG_TOML=$HOMEDIR/config/config.toml
APP_TOML=$HOMEDIR/config/app.toml
GENESIS=$HOMEDIR/config/genesis.json
TMP_GENESIS=$HOMEDIR/config/tmp_genesis.json

echo "[init.sh] Modifying genesis.json parameters..."
# Modify token denomination (in genesis.json)
jq '.app_state["staking"]["params"]["bond_denom"]="utest"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="utest"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["gov"]["params"]["min_deposit"][0]["denom"]="utest"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["evm"]["params"]["evm_denom"]="utest"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state["mint"]["params"]["mint_denom"]="utest"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

echo "[init.sh] Enabling EVM Precompiles..."
# Enable EVM Precompiles (special addresses)
jq '.app_state["evm"]["params"]["active_static_precompiles"]=["0x0000000000000000000000000000000000000100","0x0000000000000000000000000000000000000400","0x0000000000000000000000000000000000000800","0x0000000000000000000000000000000000000801","0x0000000000000000000000000000000000000802","0x0000000000000000000000000000000000000803","0x0000000000000000000000000000000000000804","0x0000000000000000000000000000000000000805"]' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

echo "[init.sh] Registering native token as ERC20 contract..."
# Register native token as ERC20 contract and define its address
jq '.app_state.erc20.params.native_precompiles=["0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"]' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
jq '.app_state.erc20.token_pairs=[{contract_owner:1,erc20_address:"0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",denom:"utest",enabled:true}]' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

echo "[init.sh] Setting max gas limit..."
# Set max gas limit
jq '.consensus_params["block"]["max_gas"]="10000000"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

echo "[init.sh] Checking for pending mode..."
# Pending mode: if the second argument is "pending", enable delayed and more fault-tolerant launch for slow network or block production
if [[ $PENDING == "pending" ]]; then
	echo "[init.sh] Pending mode enabled, modifying timeout parameters..."
	if [[ "$OSTYPE" == "darwin"* ]]; then
		sed -i '' 's/timeout_propose = "3s"/timeout_propose = "30s"/g' "$CONFIG_TOML"
		sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' "$CONFIG_TOML"
		sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' "$CONFIG_TOML"
		sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' "$CONFIG_TOML"
		sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' "$CONFIG_TOML"
		sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' "$CONFIG_TOML"
		sed -i '' 's/timeout_commit = "5s"/timeout_commit = "150s"/g' "$CONFIG_TOML"
		sed -i '' 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' "$CONFIG_TOML"
	else
		sed -i 's/timeout_propose = "3s"/timeout_propose = "30s"/g' "$CONFIG_TOML"
		sed -i 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' "$CONFIG_TOML"
		sed -i 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' "$CONFIG_TOML"
		sed -i 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' "$CONFIG_TOML"
		sed -i 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' "$CONFIG_TOML"
		sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' "$CONFIG_TOML"
		sed -i 's/timeout_commit = "5s"/timeout_commit = "150s"/g' "$CONFIG_TOML"
		sed -i 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' "$CONFIG_TOML"
	fi
fi

echo "[init.sh] Enabling Prometheus and API endpoints..."
# Enable Prometheus + API endpoints (for monitoring and using RPC/REST/gRPC)
if [[ "$OSTYPE" == "darwin"* ]]; then
	sed -i '' 's/prometheus = false/prometheus = true/' "$CONFIG_TOML"
	sed -i '' 's/prometheus-retention-time = 0/prometheus-retention-time  = 1000000000000/g' "$APP_TOML"
	sed -i '' 's/enabled = false/enabled = true/g' "$APP_TOML"
	sed -i '' 's/enable = false/enable = true/g' "$APP_TOML"

	sed -i '' 's/address = "127.0.0.1:8545"/address = "0.0.0.0:8545"/g' "$APP_TOML"
	sed -i '' 's/ws-address = "127.0.0.1:8546"/ws-address = "0.0.0.0:8546"/g' "$APP_TOML"
else
	sed -i 's/prometheus = false/prometheus = true/' "$CONFIG_TOML"
	sed -i 's/prometheus-retention-time = 0/prometheus-retention-time  = 1000000000000/g' "$APP_TOML"
	sed -i 's/enabled = false/enabled = true/g' "$APP_TOML"
	sed -i 's/enable = false/enable = true/g' "$APP_TOML"

	sed -i 's/address = "127.0.0.1:8545"/address = "0.0.0.0:8545"/g' "$APP_TOML"
	sed -i 's/ws-address = "127.0.0.1:8546"/ws-address = "0.0.0.0:8546"/g' "$APP_TOML"
fi

echo "[init.sh] Speeding up governance process time..."
# Speed up governance process (for quick testing)
sed -i.bak 's/"max_deposit_period": "172800s"/"max_deposit_period": "30s"/g' "$GENESIS"
sed -i.bak 's/"voting_period": "172800s"/"voting_period": "30s"/g' "$GENESIS"
sed -i.bak 's/"expedited_voting_period": "86400s"/"expedited_voting_period": "15s"/g' "$GENESIS"

echo "[init.sh] Setting custom pruning strategy..."
# Set custom pruning strategy (save disk and speed up testnet)
sed -i.bak 's/pruning = "default"/pruning = "custom"/g' "$APP_TOML"
sed -i.bak 's/pruning-keep-recent = "0"/pruning-keep-recent = "2"/g' "$APP_TOML"
sed -i.bak 's/pruning-interval = "0"/pruning-interval = "10"/g' "$APP_TOML"

echo "[init.sh] Blockchain initialization complete, home directory: $HOME"