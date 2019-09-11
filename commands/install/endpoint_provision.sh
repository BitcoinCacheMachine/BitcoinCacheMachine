#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

PRESEED_PATH=

for i in "$@"; do
    case $i in
        --preseed-path=*)
            PRESEED_PATH="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

sudo apt-get update -y
sudo apt-get remove lxd lxd-client -y
sudo apt-get autoremove -y
sudo apt-get install --no-install-recommends tor wait-for-it apg -y


# Ensure the user is added to the lxd group so it can use the CLI.
echo "CURRENT USER:  $(whoami)"
if groups "$(whoami)" | grep -q lxd; then
    sudo gpasswd -a "$(whoami)" lxd
fi

# install lxd via snap
# unless this is modified, we get snapshot creation in snap when removing lxd.
echo "Info: installing 'lxd' on $HOSTNAME."
sudo snap install lxd --channel="3.17/candidate"
sudo snap set system snapshots.automatic.retention=no

sleep 5

# if the PRESEED_PATH has not been set by the caller, then
# we just assume we want to do a client installation
if [[ -z $PRESEED_PATH ]]; then
    # run lxd init with --auto
    sudo lxd init --auto
else
    # run lxd init using the prepared preseed.
    cat "$PRESEED_PATH" | sudo lxd init --preseed
fi


# commands in ~/.bashrc are delimited by these literals.
BASHRC_FILE="$HOME/.bashrc"
if [[ ! -f $BASHRC_FILE ]]; then
    touch "$BASHRC_FILE"
    sudo chmod 0644 "$BASHRC_FILE"
fi

BASHRC_TEXT="export PATH=$""PATH:$HOME/.bcmcode"
source "$BASHRC_FILE"
if ! grep -qF "$BASHRC_TEXT" "$BASHRC_FILE"; then
    echo "$BASHRC_TEXT" | tee -a "$BASHRC_FILE"
fi
