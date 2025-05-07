#!/bin/bash

# Accept node index as first argument or use INDEX env var, default to 0
INDEX=${1:-${INDEX:-0}}
HOMEDIR="${2:-~/.evmd}"
OFFSET=${3:-0}

CNAME="example-starter-$INDEX"

# 原始端口
P8080=$((8080+OFFSET))

# Remove existing container
docker rm -f "$CNAME" 2>/dev/null || true

# Run the container
docker run -d \
  --name "$CNAME" \
  -p $P8080:8080 \
  -e INDEX="$INDEX" \
  -e HOME_DIR="/root/.evmd" \
  -v "$HOMEDIR":"/root/.evmd" \
  example-starter:latest

echo "Docker container started, node index: $INDEX"
echo "Listing ports: $P8080"
