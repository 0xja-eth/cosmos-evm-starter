#!/bin/bash

CHAINID=${CHAIN_ID:-cosmos_262144-1}
# Read HOME_DIR environment variable
HOMEDIR="${HOME_DIR:-~/.evmd}"
LOGLEVEL="info"

if [ ! -d "$HOMEDIR" ]; then
  echo "[start.sh] Error: Home directory not found: $HOMEDIR"
  exit 1
fi

echo "[start.sh] Starting node, log: $LOGFILE"
evmd start \
	--log_level $LOGLEVEL \
	--minimum-gas-prices=0.0001utest \
	--home "$HOMEDIR" \
	--json-rpc.api eth,txpool,personal,net,debug,web3 \
	--chain-id "$CHAINID"