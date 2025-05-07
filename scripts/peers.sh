#!/bin/bash

# Usage:
#   Add peer:    ./peers.sh add <peer_id> <peer_host> <peer_port>
#   Remove peer: ./peers.sh remove <peer_id>
# Example: ./peers.sh add abcd1234 localhost 26657

set -e

HOMEDIR="${HOME_DIR:-~/.evmd}"
CONFIG_TOML="$HOMEDIR/config/config.toml"

MODE="$1"
PEER_ID="$2"
PEER_HOST="$3"
PEER_PORT="$4"

if [ ! -f "$CONFIG_TOML" ]; then
  echo "[peers.sh] Error: Config file not found: $CONFIG_TOML"
  exit 2
fi

# Get current persistent_peers list (remove quotes)
CUR_PEERS=$(awk -F '"' '/^persistent_peers *=/ {print $2}' "$CONFIG_TOML")

if [ "$MODE" = "add" ]; then
  NEW_PEER="$PEER_ID@$PEER_HOST:$PEER_PORT"
  # If peer already exists, update it, otherwise add it
  if [[ "$CUR_PEERS" == *"$PEER_ID@"* ]]; then
    UPDATED=$(echo "$CUR_PEERS" | awk -v id="$PEER_ID" -v host="$PEER_HOST" -v port="$PEER_PORT" -F, '{
      for(i=1;i<=NF;i++){
        if($i ~ "^"id"@") {
          printf("%s%s@%s:%s", (i>1?",":""), id, host, port);
        } else {
          printf("%s%s", (i>1?",":""), $i);
        }
      }
      print ""
    }')
    echo "[peers.sh] Updated $PEER_ID to $PEER_HOST:$PEER_PORT in persistent_peers."
  else
    if [ -z "$CUR_PEERS" ]; then
      UPDATED="$NEW_PEER"
    else
      UPDATED="$CUR_PEERS,$NEW_PEER"
    fi
    echo "[peers.sh] Added $NEW_PEER to persistent_peers."
  fi
  ESCAPED_UPDATED=$(printf '%s' "$UPDATED" | sed 's/[&/|]/\\&/g')
  sed -i.bak \
    "s|^persistent_peers *=.*|persistent_peers = \"$ESCAPED_UPDATED\"|" \
    "$CONFIG_TOML"
elif [ "$MODE" = "remove" ]; then
  UPDATED=$(echo "$CUR_PEERS" | awk -v id="$PEER_ID" -F, '{
    for(i=1;i<=NF;i++){
      if($i ~ "^"id"@") nextpeer=0; else nextpeer=1;
      if(nextpeer) printf("%s%s", (i>1?",":""), $i);
    }
    print ""
  }' | sed 's/^,//;s/,$//')
  ESCAPED_UPDATED=$(printf '%s' "$UPDATED" | sed 's/[&/|]/\\&/g')
  sed -i.bak \
    "s|^persistent_peers *=.*|persistent_peers = \"$ESCAPED_UPDATED\"|" \
    "$CONFIG_TOML"
  echo "[peers.sh] Removed $PEER_ID from persistent_peers."
else
  echo "[peers.sh] Usage: $0 add <peer_id> <peer_host> <peer_port> | remove <peer_id>"
  exit 1
fi
