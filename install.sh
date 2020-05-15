#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"


DISKS_DIR="$HOME/bcm_disks"
SD_PATH="$DISKS_DIR"
HDD_PATH="$DISKS_DIR"
SSD_PATH="$DISKS_DIR"
mkdir -p "$DISKS_DIR"

for i in "$@"; do
    case $i in
        --ssd-path=*)
            SSD_PATH="${i#*=}"
            shift # past argument=value
        ;;
        --sd-path=*)
            SD_PATH="${i#*=}"
            shift # past argument=value
        ;;
        --hdd-path=*)
            HDD_PATH="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done


# first, let's check to ensure the Administrator has done their job with respect to storage
if [[ ! -d "$HDD_PATH" ]]; then
    echo "ERROR: The '$HDD_PATH' directory does not exist. Please read the BCM preparation instructions before running this script."
    exit
fi

if [[ ! -d "$SD_PATH" ]]; then
    echo "ERROR: The '$SD_PATH' directory does not exist. Please read the BCM preparation instructions before running this script."
    exit
fi

# shellcheck source=./env
#source ./env

# let's wait for apt upgrade/software locks to be released.
while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
    sleep 1
done

#install necessary software.
sudo apt-get install -y curl git apg snap snapd gnupg rsync jq pass

# removed unneeded software
sudo apt autoremove

DEFAULT_KEY_ID=
if [ -f "$HOME/.gnupg/gpg.conf" ]; then
    DEFAULT_KEY_ID="$(cat $HOME/.gnupg/gpg.conf | grep 'default-key' | awk  '{print $2}')"
fi

# if the lxd group doesn't exist, create it.
if ! grep -q lxd /etc/group; then
    addgroup --system lxd
fi

# add the user user to the lxd group
if ! groups | grep -q lxd; then
    usermod -G lxd -a "$(whoami)"
fi

# install LXD
if [[ ! -f "$(command -v lxc)" ]]; then
    sudo snap set system snapshots.automatic.retention=no
    sudo snap install lxd --channel="latest/edge"
    sleep 3
fi

BCM_GIT_DIR="$(pwd)"
export BCM_GIT_DIR="$BCM_GIT_DIR"

# Let's make sure the .ssh folder exists. This will hold known SSH BCM hosts
# SSH authentication to remote hosts uses the trezor
mkdir -p "$HOME/.ssh"
if [[ ! -f "$HOME/.ssh/authorized_keys" ]]; then
    touch "$HOME/.ssh/authorized_keys"
    chown "$USER:$USER" -R "$HOME/.ssh"
fi

# this section configured the local SSH client on the Controller
# so it uses the local SOCKS5 proxy for any SSH host that has a
# ".onion" address. We use SSH tunneling to expose the remote onion
# server's LXD API and access it on the controller via a locally
# expose port (after SSH tunneling)
SSH_LOCAL_CONF="$HOME/.ssh/config"
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
# using .profile works for both bare-metal and VM-based deployments.
BASHRC_FILE="$HOME/.profile"
BASHRC_TEXT="export PATH=\$PATH:/snap/bin:/home/$USER/bcm"
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
    LOOP_DEVICE_PATH="$1"
    STORAGE_POOL="$2"
    IMAGE_PATH="$LOOP_DEVICE_PATH/bcm-$STORAGE_POOL.img"
    
    # let's first check to see if the loop device already exists.
    LOOP_DEVICE=
    if losetup --list --output NAME,BACK-FILE | grep -q "$IMAGE_PATH"; then
        LOOP_DEVICE="$(losetup --list --output NAME,BACK-FILE | grep "$IMAGE_PATH" | head -n1 | cut -d " " -f1)"
    fi
    
    # remove the loop device and delete the image.
    if [ -n "$LOOP_DEVICE" ]; then
        sudo losetup -d "$LOOP_DEVICE"
        sudo losetup -D
    fi
    
    # if the loop file doesn't exist, create it.
    if [ ! -f "$IMAGE_PATH" ]; then
        touch "$IMAGE_PATH"
    fi
    
    truncate -s +"$3" "$IMAGE_PATH"
    # create the actual file that's backing the loop device
    #dd if=/dev/zero of="$IMAGE_PATH" bs="$3" count="$4"
    
    # next, create the loop device
    sudo losetup -fP "$IMAGE_PATH"
    
    # get the new loop device, then remove any existing filesystem entries with wipefs.
    if losetup --list --output NAME,BACK-FILE | grep -q "$IMAGE_PATH"; then
        LOOP_DEVICE="$(losetup --list --output NAME,BACK-FILE | grep "$IMAGE_PATH" | head -n1 | cut -d " " -f1)"
    fi
    
    # TODO; probably require user prompt when doing this for tagged BCMs.
    # let's wipe any existing filesystems
    if cat /proc/mounts | grep -a "$LOOP_DEVICE"; then
        sudo umount "$LOOP_DEVICE"
    fi
    sudo wipefs -a "$LOOP_DEVICE"
    
    # if the storage pool doesn't exist, we create it.
    if ! lxc storage list --format csv | grep -q "bcm-$STORAGE_POOL"; then
        
        # if the loop device exists, let's pull it into LXC as a loop device backed storage pool formatted with BTRFS
        if losetup --list --output NAME,BACK-FILE | grep -q "$IMAGE_PATH"; then
            LOOP_DEVICE="$(losetup --list --output NAME,BACK-FILE | grep $IMAGE_PATH | head -n1 | cut -d " " -f1)"
            lxc storage create "bcm-$STORAGE_POOL" btrfs source="$LOOP_DEVICE"
        else
            echo "ERROR: Loop device for storage pool '$STORAGE_POOL' does not exist! You may need to run the BCM installer script."
            exit
        fi
        
        # if the profile doesn't already exist, we create it.
        export LOOP_DEVICE="$LOOP_DEVICE"
        if ! lxc profile list --format csv | grep -q "bcm-$STORAGE_POOL"; then
            lxc profile create "bcm-$STORAGE_POOL"
        fi
        
        PROFILE_YAML="$(envsubst <./resources/lxd_profiles/$STORAGE_POOL.yml)"
        echo "$PROFILE_YAML" | lxc profile edit "bcm-$STORAGE_POOL"
    fi
    
}

createLoopDevice "$SD_PATH" sd 256MB
createLoopDevice "$SSD_PATH" ssd 10GB
createLoopDevice "$HDD_PATH" hdd 20GB

# This creates LXC storage pools for each of teh

mkdir -p "$HOME/.local/bcm/lxc"
chown -R "$USER:$USER" "$HOME/.local/bcm"

# this section creates the yml necessary to run 'lxd init'
# TODO add CLI option to specify the interface manually, then store the user's selection in ~/.bashrc
IP_OF_MACVLAN_INTERFACE="$(ip addr show "$BCM_MACVLAN_INTERFACE" | grep "inet " | cut -d/ -f1 | awk '{print $NF}')"

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
PRESEED_YAML="$(envsubst <./resources/lxd_profiles/lxd_master_preseed.yml)"
echo "$PRESEED_YAML" | gpg --batch --yes --output "$PASSWDHOME/$LXD_SERVER_NAME-lxd-preseed-yaml.gpg" --encrypt --recipient "$DEFAULT_KEY_ID"
echo "$PRESEED_YAML" | lxd init --preseed


# This for loop makes sure that all subsequent commands have access to the
# bcm LXD profiles.
for PROFILE_NAME in unprivileged privileged; do
    # if the profile doesn't already exist, we create it.
    if ! lxc profile list --format csv | grep -q "bcm-$PROFILE_NAME"; then
        lxc profile create "bcm-$PROFILE_NAME"
    fi
    
    cat "./resources/lxd_profiles/$PROFILE_NAME.yml" | lxc profile edit "bcm-$PROFILE_NAME"
done