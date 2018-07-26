#!/bin/bash

# # change permissions and execute /entrypoint.sh
lxc exec manager1 -- chmod +x /apps/bitcoin/bitcoinstack/up.sh
lxc exec manager1 -- bash -c /apps/bitcoin/bitcoinstack/up.sh
