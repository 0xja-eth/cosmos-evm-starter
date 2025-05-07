set -e

mkdir -p nodes
cp ./config/nodes.example.json ./config/nodes.json

# --build option: all/starter/node/false (default: all)
BUILD_TYPE="all"

if [[ $1 == "--build" ]]; then
  BUILD_TYPE="$2"
fi

case "$BUILD_TYPE" in
  all)
    echo "Building all docker images..."
    sh docker/build.sh
    ;;
  starter)
    echo "Building starter docker image..."
    sh docker/build-starter.sh
    ;;
  node)
    echo "Building node docker image..."
    sh docker/build-node.sh
    ;;
  false)
    echo "Skip docker build."
    ;;
  *)
    echo "Unknown --build option: $BUILD_TYPE" >&2
    exit 1
    ;;
esac

echo "Starting docker containers..."

sh docker/run-starter.sh 0 ./nodes/node0 0
sh docker/run-starter.sh 1 ./nodes/node1 100

echo "Initializing blockchain ..."
curl -X POST http://localhost:8080/run/init
curl -X POST http://localhost:8180/run/init

echo "Allocating genesis accounts ..."
curl -X POST http://localhost:8080/run/allocate
curl -X POST http://localhost:8180/run/allocate

echo "Generating txs ..."
curl -X POST http://localhost:8080/run/gentx
curl -X POST http://localhost:8180/run/gentx

# Manually copy gentx
#cp ./nodes/node0/config/gentx/* ./nodes/node1/config/gentx/
cp ./nodes/node1/config/gentx/* ./nodes/node0/config/gentx/

curl -X POST http://localhost:8080/run/collect

cp ./nodes/node0/config/genesis.json ./nodes/node1/config/genesis.json

NODE0_ID=$(curl -s -X GET http://localhost:8080/run/node | jq -r '.stdout')
NODE1_ID=$(curl -s -X GET http://localhost:8180/run/node | jq -r '.stdout')
echo "Node0 ID: $NODE0_ID"
echo "Node1 ID: $NODE1_ID"

echo "Adding peers..."
curl -X POST -H "Content-Type: application/json" -d '{"args":["add","'$NODE1_ID'","example-node-1","26656"]}' http://localhost:8080/run/peers
curl -X POST -H "Content-Type: application/json" -d '{"args":["add","'$NODE0_ID'","example-node-0","26656"]}' http://localhost:8180/run/peers

docker stop example-starter-0
docker stop example-starter-1

sh docker/run-node.sh 0 ./nodes/node0 1001
sh docker/run-node.sh 1 ./nodes/node1 1051

echo "Both nodes started."


