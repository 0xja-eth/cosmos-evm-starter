#!/bin/bash

# Accept node index as first argument or use INDEX env var, default to 0
INDEX=${1:-${INDEX:-0}}
HOMEDIR="${2:-~/.evmd}"
OFFSET=${3:-0}

CNAME="example-node-$INDEX"

# 原始端口
P26656=$((26656+OFFSET))
P26657=$((26657+OFFSET))
P8545=$((8545+OFFSET))
P8546=$((8546+OFFSET))
P1317=$((1317+OFFSET))

# Remove existing container
docker rm -f "$CNAME" 2>/dev/null || true

docker network inspect example-net >/dev/null 2>&1 || docker network create example-net

# Run the container
docker run -d \
  --name "$CNAME" \
  --network example-net \
  -p $P26656:26656 \
  -p $P26657:26657 \
  -p $P8545:8545 \
  -p $P8546:8546 \
  -p $P1317:1317 \
  -e INDEX="$INDEX" \
  -e HOME_DIR="/root/.evmd" \
  -v "$HOMEDIR":"/root/.evmd" \
  example-node:latest

echo "Docker container started, node index: $INDEX"
echo "Listing ports: $P26656 $P26657 $P8545 $P8546 $P1317"
