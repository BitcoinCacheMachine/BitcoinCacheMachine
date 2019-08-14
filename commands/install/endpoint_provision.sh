#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

PRESEED_PATH="/home/bcm/bcm"

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
sudo apt-get install --no-install-recommends tor wait-for-it -y

# install lxd via snap
if [ ! -x "$(command -v lxd)" ]; then
    # unless this is modified, we get snapshot creation in snap when removing lxd.
    echo "Info: 'lxd' is not installed."
    sudo snap install lxd --channel=stable
    sudo snap set system snapshots.automatic.retention=no
fi

# if the 'bcm' user doesn't exist, let's create it and add it
# to the NOPASSWD sudoers list (like we have in cloud-init provisioned machines)
if groups "$USER" | grep -q lxd; then
    sudo adduser bcm
    sudo gpasswd -a "${USER}" lxd
fi

# run lxd init using the prepared preseed.
cat "$PRESEED_PATH" | sudo lxd init --preseed
