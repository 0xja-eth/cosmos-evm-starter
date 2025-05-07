1. 链准备阶段：将区块链代码通过 github 同步到各个节点上，然后执行 make install

   执行 [install.sh](scripts/install.sh)：
    ```bash
    git clone https://github.com/0xja-eth/example_evm_chain
    cd example_evm_chain
    make install
    ```

3. 链启动阶段：由一个节点确定创世文件，并定义好代币分配

   首先，我们选定一个节点作为主要节点（即 Ignite Network 里面的 Coordinator），我们称这个节点为 `node0`，在这个节点上先进行 `init` 操作：

   执行 [init.sh](scripts/init.sh)：
    ```bash
    MONIKER=node0 # 节点名称
    CHAINID=cosmos_262144-1
    HOMEDIR="~/.evmd" # 可以自己指定一个 HOMEDIR
    
    evmd init $MONIKER -o --chain-id "$CHAINID" --home "$HOMEDIR"

    # 除了简单的 init 操作之外，我们还需要对其生成的配置文件做修改：

    # 定义节点配置中各文件路径，后续需要逐个修改以启动区块链
    CONFIG=$HOMEDIR/config/config.toml
    APP_TOML=$HOMEDIR/config/app.toml
    GENESIS=$HOMEDIR/config/genesis.json
    TMP_GENESIS=$HOMEDIR/config/tmp_genesis.json
    
    # 修改代币单位（genesis.json 文件）
    jq '.app_state["staking"]["params"]["bond_denom"]="utest"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="utest"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    jq '.app_state["gov"]["params"]["min_deposit"][0]["denom"]="utest"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    jq '.app_state["evm"]["params"]["evm_denom"]="utest"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    jq '.app_state["mint"]["params"]["mint_denom"]="utest"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    
    # 启用 EVM Precompiles（特殊的地址）
    jq '.app_state["evm"]["params"]["active_static_precompiles"]=["0x0000000000000000000000000000000000000100","0x0000000000000000000000000000000000000400","0x0000000000000000000000000000000000000800","0x0000000000000000000000000000000000000801","0x0000000000000000000000000000000000000802","0x0000000000000000000000000000000000000803","0x0000000000000000000000000000000000000804","0x0000000000000000000000000000000000000805"]' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    
    # 注册原生代币为 ERC20 合约并定义其地址
    jq '.app_state.erc20.params.native_precompiles=["0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"]' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    jq '.app_state.erc20.token_pairs=[{contract_owner:1,erc20_address:"0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",denom:"utest",enabled:true}]' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    
    # 设置最大 Gas 限制
    jq '.consensus_params["block"]["max_gas"]="10000000"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
    
    # 延迟模式（Pending mode），当传入的第一个参数是 "pending" 时候启用
    # 以延迟更久、容错更强的方式启动链，以便于等待交易广播、模拟慢网络或处理较慢的出块
    if [[ $1 == "pending" ]]; then
    	if [[ "$OSTYPE" == "darwin"* ]]; then
    		sed -i '' 's/timeout_propose = "3s"/timeout_propose = "30s"/g' "$CONFIG"
    		sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' "$CONFIG"
    		sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' "$CONFIG"
    		sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' "$CONFIG"
    		sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' "$CONFIG"
    		sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' "$CONFIG"
    		sed -i '' 's/timeout_commit = "5s"/timeout_commit = "150s"/g' "$CONFIG"
    		sed -i '' 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' "$CONFIG"
    	else
    		sed -i 's/timeout_propose = "3s"/timeout_propose = "30s"/g' "$CONFIG"
    		sed -i 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' "$CONFIG"
    		sed -i 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' "$CONFIG"
    		sed -i 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' "$CONFIG"
    		sed -i 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' "$CONFIG"
    		sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' "$CONFIG"
    		sed -i 's/timeout_commit = "5s"/timeout_commit = "150s"/g' "$CONFIG"
    		sed -i 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' "$CONFIG"
    	fi
    fi
    
    # 开启 Prometheus + API 接口（方便监控和使用 RPC/REST/gRPC 接口）
    if [[ "$OSTYPE" == "darwin"* ]]; then
    	sed -i '' 's/prometheus = false/prometheus = true/' "$CONFIG"
    	sed -i '' 's/prometheus-retention-time = 0/prometheus-retention-time  = 1000000000000/g' "$APP_TOML"
    	sed -i '' 's/enabled = false/enabled = true/g' "$APP_TOML"
    	sed -i '' 's/enable = false/enable = true/g' "$APP_TOML"
    else
    	sed -i 's/prometheus = false/prometheus = true/' "$CONFIG"
    	sed -i 's/prometheus-retention-time  = "0"/prometheus-retention-time  = "1000000000000"/g' "$APP_TOML"
    	sed -i 's/enabled = false/enabled = true/g' "$APP_TOML"
    	sed -i 's/enable = false/enable = true/g' "$APP_TOML"
    fi
    
    # 加快治理流程时间（方便快速测试）
    sed -i.bak 's/"max_deposit_period": "172800s"/"max_deposit_period": "30s"/g' "$GENESIS"
    sed -i.bak 's/"voting_period": "172800s"/"voting_period": "30s"/g' "$GENESIS"
    sed -i.bak 's/"expedited_voting_period": "86400s"/"expedited_voting_period": "15s"/g' "$GENESIS"
    
    # 设置自定义修剪策略（节省测试网磁盘空间和启动速度）
    sed -i.bak 's/pruning = "default"/pruning = "custom"/g' "$APP_TOML"
    sed -i.bak 's/pruning-keep-recent = "0"/pruning-keep-recent = "2"/g' "$APP_TOML"
    sed -i.bak 's/pruning-interval = "0"/pruning-interval = "10"/g' "$APP_TOML"
    ```

   接下来，为了更方便我们操作，我们直接将需要分配代币的钱包生成出来（所有节点的钱包），用以下指令生成一个钱包（以下助记词来源于 `cosmos/evm` 仓库的启动代码，仅用于测试）：

   执行 [allocate.sh](scripts/allocate.sh)：
    ```bash
    # node0 address 0x7cb61d4117ae31a12e393a1cfa3bac666481d02e | os10jmp6sgh4cc6zt3e8gw05wavvejgr5pwjnpcky
    NODE0_KEY="node0"
    NODE0_MNEMONIC="gesture inject test cycle original hollow east ridge hen combine junk child bacon zero hope comfort vacuum milk pitch cage oppose unhappy lunar seat"
    NODE0_BALANCE=100000000000000000000000000utest
    
    # node1 address 0xc6fe5d33615a1c52c08018c47e8bc53646a0e101 | os1cml96vmptgw99syqrrz8az79xer2pcgp84pdun
    NODE1_KEY="node1"
    NODE1_MNEMONIC="copper push brief egg scan entry inform record adjust fossil boss egg comic alien upon aspect dry avoid interest fury window hint race symptom"
    NODE1_BALANCE=1000000000000000000000000utest
    
    KEYALGO="eth_secp256k1"
    KEYRING="test"
    
    echo "$NODE0_MNEMONIC" | evmd keys add "$NODE0_KEY" --recover --keyring-backend "$KEYRING" --algo "$KEYALGO"
    evmd genesis add-genesis-account "$NODE0_KEY" "$NODE0_BALANCE" --keyring-backend "$KEYRING" --home "$HOMEDIR"
    
    echo "$NODE1_MNEMONIC" | evmd keys add "$NODE1_KEY" --recover --keyring-backend "$KEYRING" --algo "$KEYALGO"
    evmd genesis add-genesis-account "$NODE1_KEY" "$NODE1_BALANCE" --keyring-backend "$KEYRING" --home "$HOMEDIR"
    ```

   好了，链的基础配置已经完成。

3. 链协调阶段：验证者节点加入网络，生成质押交易（gentx）

   在每个验证者节点（假设为 node1）上执行 `init` 操作：

   执行 [init.sh](scripts/init.sh)：
    ```bash
    MONIKER=node1 # 节点名称
    CHAINID=cosmos_262144-1
    HOMEDIR="~/.evmd" # 可以自己指定一个 HOMEDIR
    
    evmd init $MONIKER -o --chain-id "$CHAINID" --home "$HOMEDIR"
   
    # 和前面是一样的操作，这里不给出了
    ```

   接下来，将前面生成的钱包导入到各自的验证者节点上，并执行 `gentx`：

   执行 [gentx.sh](scripts/gentx.sh)：
    ```bash
    NODE_KEY="dev0"
    NODE_MNEMONIC="copper push brief egg scan entry inform record adjust fossil boss egg comic alien upon aspect dry avoid interest fury window hint race symptom"
    AMOUNT=1000000000000000000000utest
    BASEFEE=10000000
    
    KEYALGO="eth_secp256k1"
    KEYRING="test"
    
    echo "$NODE_MNEMONIC" | evmd keys add "$NODE_KEY" --recover --keyring-backend "$KEYRING" --algo "$KEYALGO"
    evmd genesis gentx "$NODE_KEY" "$AMOUNT" --gas-prices ${BASEFEE}utest --keyring-backend "$KEYRING" --chain-id "$CHAINID" --home "$HOMEDIR"
    ```

   然后将每个节点的 `gentx-*.json` 文件归集到 node0（主节点）的 `gentx` 文件夹内，回到主节点，执行：

    ```bash
    evmd genesis collect-gentxs --home "$HOMEDIR"
    ```

   将最终的 `genesis.json` 文件分发到各个验证者节点上，覆盖这些节点上已有的 `genesis.json`。

   接下来，确保各个节点网络能连通，然后配置各自的 peer 等信息：

如何在