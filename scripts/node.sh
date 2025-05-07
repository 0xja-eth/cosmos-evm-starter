#!/bin/bash
# Usage: ./node.shHOME_DIR

HOMEDIR="${HOME_DIR:-~/.evmd}"
CONFIG_TOML=$HOMEDIR/config/config.toml

if [ ! -f "$CONFIG_TOML" ]; then
  echo "[node.sh] Error: Config file not found: $CONFIG_TOML"
  exit 1
fi

NODE_ID=$(evmd tendermint show-node-id --home "$HOMEDIR")

if [ $? -ne 0 ]; then
  echo "[node.sh] Failed to get node id."
  exit 2
fi

echo "$NODE_ID"
