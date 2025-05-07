#!/bin/bash

REPO_URL="https://github.com/0xja-eth/example_evm_chain"
REPO_NAME="example_evm_chain"

echo "[install.sh] Cloning $REPO_URL..."
git clone $REPO_URL
cd $REPO_NAME

echo "[install.sh] Installing $REPO_NAME..."
make install

echo "[install.sh] Installation complete!"