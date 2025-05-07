#!/bin/bash

docker network create example-net

# Build the Docker image
docker build -t example-starter:latest .
docker build -f Dockerfile.node -t example-node:latest .
