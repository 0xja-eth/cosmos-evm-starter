# Build from Ubuntu 22.04
#FROM ubuntu:22.04
#
## Install dependencies
#RUN apt-get update && \
#    apt-get install -y git make jq curl build-essential
#
## Install Go 1.23.8
#RUN curl -OL https://go.dev/dl/go1.23.8.linux-amd64.tar.gz && \
#    tar -C /usr/local -xzf go1.23.8.linux-amd64.tar.gz && \
#    rm go1.23.8.linux-amd64.tar.gz
#ENV PATH="/usr/local/go/bin:${PATH}"

# Build from golang:1.23.8-bullseye
FROM golang:1.23.8-bullseye

# Install dependencies
RUN apt-get update && \
    apt-get install -y git make jq curl build-essential

WORKDIR /root

# Copy scripts and configuration files into the container
COPY . .

RUN chmod +x scripts -R
RUN scripts/install.sh

#RUN git clone https://github.com/0xja-eth/example_evm_chain
#RUN cd example_evm_chain && make install

# Build Go HTTP API server
RUN go build -o node-api main.go

# Expose ports (adjust as needed for your chain configuration)
EXPOSE 26656 26657 8545 8546 1317 8080

# Run the Go API server by default
CMD ["/root/node-api"]