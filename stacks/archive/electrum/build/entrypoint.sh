#!/bin/bash

set -Eeoux

python3 Electrum-3.3.8/run_electrum -D /home/user/.electrum --oneserver --server="$BACK_END_IP:$ELECTRS_RPC_PORT:t" "$ELECTRUM_CMD_TXT"
