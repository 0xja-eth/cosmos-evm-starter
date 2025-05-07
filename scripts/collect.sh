#!/bin/bash

HOMEDIR="${HOME_DIR:-~/.evmd}"

evmd genesis collect-gentxs --home "$HOMEDIR"
evmd genesis validate-genesis --home "$HOMEDIR" # 确保 genesis 没问题，可以再执行这个指令