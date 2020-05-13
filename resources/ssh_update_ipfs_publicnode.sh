#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

PRIVATE_KEY_PATH="$HOME/.ssh/aws.pem"

for i in "$@"; do
    case $i in
        --key-path=*)
            PRIVATE_KEY_PATH="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $REMOTE_HOSTNAME ]]; then
    echo "REMOTE_HOSTNAME cannot be empty. Please set your environment."
    exit
fi

wait-for-it -t 0 "$REMOTE_HOSTNAME:22"

ssh -i "$PRIVATE_KEY_PATH"  "ubuntu@$REMOTE_HOSTNAME" << EOF
    DEBIAN_FRONTEND=noninteractive
    sudo apt update
    sudo apt-get install -y wait-for-it
    #sudo apt upgrade -y

    wget https://dist.ipfs.io/go-ipfs/v0.4.23/go-ipfs_v0.4.23_linux-amd64.tar.gz
    tar xvfz go-ipfs_v0.4.23_linux-amd64.tar.gz
    cd go-ipfs && sudo bash -c ./install.sh
    ipfs init
    ipfs daemon &
    #wait-for-it -t 60
EOF

sleep 15

ssh -i "$PRIVATE_KEY_PATH" "ubuntu@$REMOTE_HOSTNAME" << EOF
    ipfs get QmcJHKQV6GVDRXLRDxHKMJvETxUTMcGwtgerF6T3JLqtnG
EOF
