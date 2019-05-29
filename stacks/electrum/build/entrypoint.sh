#!/bin/bash

set -Eeu

python3 Electrum-3.3.6/run_electrum -D /home/user/.electrum --oneserver --server="$BACK_END_IP:$ELECTRS_RPC_PORT:t" "$ELECTRUM_CMD_TXT"
