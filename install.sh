#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# first, let's check to ensure the Administrator has done their job with respect to storage
if [[ ! -d /hdd ]]; then
    echo "ERROR: The '/hdd' directory does not exist. Please read the BCM preparation instructions before running this script."
    exit
fi

if [[ ! -d /sd ]]; then
    echo "ERROR: The '/sd' directory does not exist. Please read the BCM preparation instructions before running this script."
    exit
fi


source ./env

# let's wait for apt upgrade/software locks to be released.
while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
    sleep 1
done

#install necessary software.
apt-get install -y curl git apg snap snapd gnupg rsync jq

# if the lxd group doesn't exist, create it.
if ! grep -q lxd /etc/group; then
    addgroup --system lxd
fi

# add the SUDO_USER user to the lxd group
if ! groups | grep -q lxd; then
    usermod -G lxd -a "$SUDO_USER"
fi

# install LXD
if [[ ! -f "$(command -v lxc)" ]]; then
    snap set system snapshots.automatic.retention=no
    snap install lxd --channel="latest/edge"
fi

export BCM_GIT_DIR="$(pwd)"
SUDO_USER_HOME="/home/$SUDO_USER"

# Let's make sure the .ssh folder exists. This will hold known SSH BCM hosts
# SSH authentication to remote hosts uses the trezor
mkdir -p "$SUDO_USER_HOME/.ssh"
if [[ ! -f "$SUDO_USER_HOME/.ssh/authorized_keys" ]]; then
    touch "$SUDO_USER_HOME/.ssh/authorized_keys"
    chown "$SUDO_USER:$SUDO_USER" -R "$SUDO_USER_HOME/.ssh"
fi

# this section configured the local SSH client on the Controller
# so it uses the local SOCKS5 proxy for any SSH host that has a
# ".onion" address. We use SSH tunneling to expose the remote onion
# server's LXD API and access it on the controller via a locally
# expose port (after SSH tunneling)
SSH_LOCAL_CONF="$SUDO_USER_HOME/.ssh/config"
if [[ ! -f "$SSH_LOCAL_CONF" ]]; then
    # if the .ssh/config file doesn't exist, create it.
    touch "$SSH_LOCAL_CONF"
fi

# Next, paste in the necessary .ssh/config settings for accessing
# remote SSH services exposed as an onion. This will make any 'ssh' command
# redirect all .onion hostnames to your tor SOCKS5 proxy.
if [[ -f "$SSH_LOCAL_CONF" ]]; then
    SSH_ONION_TEXT="Host *.onion"
    if ! grep -Fxq "$SSH_ONION_TEXT" "$SSH_LOCAL_CONF"; then
        {
            echo "$SSH_ONION_TEXT"
            echo "    ProxyCommand nc -xlocalhost:9050 -X5 %h %p"
        } >>"$SSH_LOCAL_CONF"
    fi
fi

# let's ensure the image has /snap/bin in its PATH environment variable.
# using .profile works for both bare-metal and VM-based (multipass) deployments.
BASHRC_FILE="$SUDO_USER_HOME/.profile"
BASHRC_TEXT="export PATH=$""PATH:/snap/bin"
if ! grep -qF "$BASHRC_TEXT" "$BASHRC_FILE"; then
    {
        echo "$BASHRC_TEXT"
        echo "DEBIAN_FRONTEND=noninteractive"
    } >> "$BASHRC_FILE"
fi


# in this section, we configure the underlying storage. We create LOOP devices storated
# at /sd /ssd and /hdd. The ADMINISTRATOR MUST mount these directories BEFORE running this
# install script.
function createLoopDevice () {
    IMAGE_PATH="$1/bcm-$2.img"
    
    # let's first check to see if the loop device already exists.
    LOOP_DEVICE=
    if losetup --list --output NAME,BACK-FILE | grep -q "$IMAGE_PATH"; then
        LOOP_DEVICE="$(losetup --list --output NAME,BACK-FILE | grep "$IMAGE_PATH" | head -n1 | cut -d " " -f1)"
    fi
    
    # remove the loop device and delete the image.
    if [ -n "$LOOP_DEVICE" ]; then
        losetup -d "$LOOP_DEVICE"
        
        # remove the file so we can start anew.
        if [ -f "$IMAGE_PATH" ]; then
            sleep 2
            rm "$IMAGE_PATH"
        fi
    fi
    
    # create the actual file that's backing the loop device
    dd if=/dev/zero of="$IMAGE_PATH" bs="$3" count=1
    
    # next, create the loop device
    losetup -fP "$IMAGE_PATH"
}


createLoopDevice "/sd" "sd" 262144000
createLoopDevice "/home/$SUDO_USER" "ssd" 4194304000
createLoopDevice "/hdd" "hdd" 1048576000


# this section creates the yml necessary to run 'lxd init'
# TODO add CLI option to specify the interface manually, then store the user's selection in ~/.bashrc
IP_OF_MACVLAN_INTERFACE="$(ip addr show $BCM_MACVLAN_INTERFACE | grep "inet " | cut -d/ -f1 | awk '{print $NF}')"
BCM_LXD_SECRET="$(apg -n 1 -m 30 -M CN)"
export BCM_LXD_SECRET="$BCM_LXD_SECRET"
LXD_SERVER_NAME="$(hostname)"
# these two lines are so that ssh hosts can have the correct naming convention for LXD node info.
if [[ ! "$LXD_SERVER_NAME" == *"-01"* ]]; then
    LXD_SERVER_NAME="$LXD_SERVER_NAME-01"
fi

if [[ ! "$LXD_SERVER_NAME" == *"bcm-"* ]]; then
    LXD_SERVER_NAME="bcm-$LXD_SERVER_NAME"
fi

export LXD_SERVER_NAME="$LXD_SERVER_NAME"
export IP_OF_MACVLAN_INTERFACE="$IP_OF_MACVLAN_INTERFACE"
PRESEED_YAML="$(envsubst <./resources/lxd_master_preseed.yml)"
echo "$PRESEED_YAML" | lxd init --preseed

mkdir -p "$SUDO_USER_HOME/.local/bcm/lxc"
chown -R "$SUDO_USER:$SUDO_USER" "$SUDO_USER_HOME/.local/bcm"
