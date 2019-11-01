#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

MODE=tm

for i in "$@"; do
    case $i in
        --mode=*)
            MODE="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if docker ps | grep -q "bcm_electrum_$BCM_ACTIVE_CHAIN"; then
    echo "WARNING: The electrum docker container 'bcm_electrum_$BCM_ACTIVE_CHAIN' appears to be running! Exiting."
    exit
fi

if [[ $MODE != "tm" && $MODE != "tor" ]]; then
    echo "ERROR: Valid modes are 'tm' for trust minimized (meaning you consult a self-hosted back-end) and 'tor' to connect electrum wallet to remote untrusted servers using tor."
    echo "Note that 'tor' allows an untrusted third party to know all UTXOs belonging to your wallet, but will NOT necessarily know who owns those UTXOs."
    exit -1
fi

if [[ $MODE == "tm" ]]; then
    # ensure the back end is provisioned.
    if ! lxc exec "$BCM_MANAGER_HOST_NAME" -- docker stack list --format '{{ .Name }}' | grep "$BCM_ACTIVE_CHAIN" | grep -q "$STACK_NAME" | grep -q "electrs"; then
        bcm stack start electrs
    fi
fi

# Using Electrum Wallet 3.3.5
bash -c "$BCM_GIT_DIR/controller/build.sh"
docker build -t bcm-electrum:"$BCM_VERSION" --build-arg BCM_VERSION="$BCM_VERSION" ./build/


export ELECTRUM_DIR="$HOME/.electrum" && mkdir -p "$ELECTRUM_DIR"
mkdir -p "$ELECTRUM_DIR/regtest"
mkdir -p "$ELECTRUM_DIR/testnet"
cp ./regtest_config.json "$ELECTRUM_DIR/regtest/config"
cp ./testnet_config.json "$ELECTRUM_DIR/testnet/config"
cp ./mainnet_config.json "$ELECTRUM_DIR/config"

XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch $XAUTH
xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -

# let's check on our back end services.
BACK_END_IP="$(bcm get-ip)"

# shellcheck source=../electrs/env.sh
source "$BCM_STACKS_DIR/electrs/env.sh"

wait-for-it -t 0 "$BACK_END_IP:$ELECTRS_RPC_PORT"

ELECTRUM_CMD_TXT=""
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    ELECTRUM_CMD_TXT="--testnet"
    elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
    ELECTRUM_CMD_TXT="--regtest"
fi

# todo review permissions on this app running.
docker run -it --rm --net=host --name="bcm_electrum_$BCM_ACTIVE_CHAIN" \
-e DISPLAY="$DISPLAY" \
-e XAUTHORITY="${XAUTH}" \
-e BACK_END_IP="$BACK_END_IP" \
-e ELECTRS_RPC_PORT="$ELECTRS_RPC_PORT" \
-e ELECTRUM_CMD_TXT="$ELECTRUM_CMD_TXT" \
-v "$XSOCK":"$XSOCK":rw \
-v "$XAUTH":"$XAUTH":rw \
-v "$ELECTRUM_DIR":/home/user/.electrum \
--privileged \
bcm-electrum:"$BCM_VERSION"
