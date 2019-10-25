#!/bin/bash

set -eu

# get the codename, usually bionic or debian
CODE_NAME="$(< /etc/os-release grep VERSION_CODENAME | cut -d "=" -f 2)"

# add the tor apt repository
echo "deb https://deb.torproject.org/torproject.org $CODE_NAME main" | sudo tee -a /etc/apt/sources.list
echo "deb-src https://deb.torproject.org/torproject.org $CODE_NAME main" | sudo tee -a /etc/apt/sources.list

# download the tor PGP key and add it as a trusted key to apt
curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | sudo gpg --import
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -

# update apt and install pre-reqs
sudo apt-get update
sudo apt-get remove lxd lxd-client -y
sudo apt-get autoremove -y
sudo apt-get install -y tor curl wait-for-it git deb.torproject.org-keyring iotop socat

# wait for local tor to come online.
wait-for-it -t 30 127.0.0.1:9050

# configure git to download through the local tor proxy.
BCM_GITHUB_REPO_URL="https://github.com/BitcoinCacheMachine/BitcoinCacheMachine"
git config --global http.$BCM_GITHUB_REPO_URL.proxy socks5://127.0.0.1:9050

# clone the BCM repo to $HOME/git/github/bcm
BCM_GIT_DIR="$HOME/git/github/bcm"
git clone "$BCM_GITHUB_REPO_URL" "$BCM_GIT_DIR"

cd "$BCM_GIT_DIR" && git checkout dev

# install LXD
if [[ ! -f "$(command -v lxc)" ]]; then
    # install lxd via snap
    # unless this is modified, we get snapshot creation in snap when removing lxd.
    echo "INFO: Installing 'lxd' on $HOSTNAME."
    sudo snap install lxd --channel="candidate"
    sudo snap set system snapshots.automatic.retention=no
    sleep 5
fi

# if the lxd group doesn't exist, create it.
if ! grep -q lxd /etc/group; then
    sudo addgroup --system lxd
fi

if ! groups | grep -q lxd; then
    sudo useradd -g lxd -g sudo -m "$(whoami)"
fi



# configure SSH
###################
if [[ ! -f "$HOME/.ssh/authorized_keys" ]]; then
    sudo touch "$HOME/.ssh/authorized_keys"
    sudo chown "$(whoami):lxd" -R "$HOME/.ssh"
fi

# TODO verify where we need this.
sudo touch "/etc/sudoers.d/$(whoami)"
echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee -a "/etc/sudoers.d/$(whoami)"

# update /etc/ssh/sshd_config to listen for incoming SSH connections on all interfaces.
if ! grep -Fxq "ListenAddress 0.0.0.0" /etc/ssh/sshd_config; then
    {
        echo "ListenAddress 127.0.0.1"
        echo "ListenAddress 0.0.0.0"
    } | sudo tee -a /etc/ssh/sshd_config
fi

sudo systemctl restart ssh
wait-for-it -t 15 127.0.0.1:22
# end configure SSH
#####################

# install docker
if [[ ! -f "$(command -v docker)" ]]; then
    echo "INFO: Installing 'docker' locally using snap."
    sudo snap install docker --channel="stable"
    sleep 2
    
    if ! grep -q docker /etc/group; then
        sudo groupadd docker
    fi
    
    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
    fi
    
    # next we need to determine the underlying file system so we can upload the correct daemon.json
    DEVICE="$(df -h "$HOME" | grep ' /' | awk '{print $1}')"
    FILESYSTEM="$(mount | grep "$DEVICE")"
    
    DAEMON_CONFIG="$BCM_GIT_DIR/commands/install/overlay_daemon.json"
    if echo "$FILESYSTEM" | grep -q "btrfs"; then
        DAEMON_CONFIG="$BCM_GIT_DIR/commands/install/btrfs_daemon.json"
        DEST_DAEMON_FILE="/var/snap/docker/current/config/daemon.json"
        echo "INFO: Setting dockerd daemon settings to $DEST_DAEMON_FILE"
        sudo cp "$DAEMON_CONFIG" "$DEST_DAEMON_FILE"
        sudo snap restart docker
    fi
fi


BASHRC_FILE="$HOME/.bashrc"
BASHRC_TEXT="export PATH=$""PATH:$HOME/git/github/bcm"
source "$BASHRC_FILE"
if ! grep -qF "$BASHRC_TEXT" "$BASHRC_FILE"; then
    echo "$BASHRC_TEXT" | tee -a "$BASHRC_FILE"
    exit
fi


echo "WARNING: Please logout or restart your computer before continuing with BCM!"