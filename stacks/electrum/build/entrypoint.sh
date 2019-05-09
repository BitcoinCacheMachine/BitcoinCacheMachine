#!/bin/bash

set -ex

python3 Electrum-3.3.5/run_electrum -D /home/user/.electrum --oneserver --server="$BACK_END_IP:$ELECTRS_RPC_PORT:t" "$ELECTRUM_CMD_TXT"
