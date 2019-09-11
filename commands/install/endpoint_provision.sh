#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

echo "IN ENDPOINT_PROVISION"
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
if groups "$USER" | grep -q lxd; then
    sudo gpasswd -a "${USER}" lxd
fi


# install lxd via snap
# unless this is modified, we get snapshot creation in snap when removing lxd.
echo "Info: installing 'lxd' on $HOSTNAME."
sudo snap install lxd --channel="3.17/candidate"
sudo snap set system snapshots.automatic.retention=no

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

source "$BASHRC_FILE"
if ! echo "$PATH" | grep -q $BASHRC_TEXT; then
    echo "Updating ~/.bashrc."
    BASHRC_TEXT="export PATH=$""PATH:""$(pwd)"
    echo "$BASHRC_TEXT" >>"$BASHRC_FILE"
fi
