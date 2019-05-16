#!/bin/bash

# sets your SDN controller (laptop/desktop) environment up for BCM

set -Eeuo pipefail
cd "$(dirname "$0")"

# let's set the local git client user and email settings to prevent error messages
# related to an unconfigured git client. Test
if [[ -z $(git config --get --local user.name) ]]; then
    git config --local user.name "bcm"
fi

if [[ -z $(git config --get --local user.email) ]]; then
    git config --local user.email "bcm@$(hostname)"
fi

# let's install all necessary software at the SDN controller.
sudo apt-get install -y --no-install-recommends wait-for-it openssh-server netcat encfs avahi-discover
bash -c "$BCM_GIT_DIR/commands/install/snap_install_docker.sh"
bash -c "$BCM_GIT_DIR/commands/install/snap_install_lxd_local.sh"

# let's make sure the local git client is using TOR for git pull operations.
# this should have been configured on a global level already when the user initially
# downloaded BCM from github
BCM_TOR_PROXY="socks5://localhost:9050"
if [[ $(git config --get --local http.proxy) != "$BCM_TOR_PROXY" ]]; then
    echo "Setting git client to use local SOCKS5 TOR proxy for push/pull operations."
    git config --local http.proxy "$BCM_TOR_PROXY"
fi

# get the current directory where this script is so we can set ENVs in ~/.bashrc
echo "Setting BCM_GIT_DIR environment variable in current shell to '$(pwd)'"
BCM_GIT_DIR="$(pwd)"
export BCM_GIT_DIR="$BCM_GIT_DIR"

# commands in ~/.bashrc are delimited by these literals.
BASHRC_FILE="$HOME/.bashrc"
BCM_BASHRC_START_FLAG='###START_BCM###'
BCM_BASHRC_END_FLAG='###END_BCM###'

if [[ ! -f $BASHRC_FILE ]]; then
    touch "$BASHRC_FILE"
    sudo chmod 0644 "$BASHRC_FILE"
fi

if grep -Fxq "$BCM_BASHRC_START_FLAG" "$BASHRC_FILE"; then
    echo "BCM flag discovered in '$BASHRC_FILE'. Please inspect your '$BASHRC_FILE' to clear any BCM-related content, if appropriate."
else
    echo "Writing commands to '$BASHRC_FILE' to enable the BCM CLI."
    {
        echo ""
        echo "$BCM_BASHRC_START_FLAG"
        echo "export BCM_GIT_DIR=$BCM_GIT_DIR"
        # shellcheck disable=SC2016
        echo "export PATH="'$PATH:'""'$BCM_GIT_DIR'""
        echo "export BCM_ACTIVE=1"
        echo "export BCM_DEBUG=1"
        echo "export BCM_LXD_IMAGE_CACHE="
        echo "export BCM_DOCKER_IMAGE_CACHE=registry-1.docker.io"
        echo "$BCM_BASHRC_END_FLAG"
    } >>"$BASHRC_FILE"
fi

# configure encfs/FUSE mount settings.
if [[ -f /etc/fuse.conf ]]; then
    if grep -q "#user_allow_other" </etc/fuse.conf; then
        # update /etc/fuse.conf to allow non-root users to specify the allow_root mount option
        sudo sed -i -e 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf
    fi
fi

# let's ensure directories exist for bcm cli commands OUTSIDE of ~/.bcm
mkdir -p "$HOME/.gnupg"
mkdir -p "$HOME/.password_store"

SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"

# configure sshd on the SDN controller. This allows you to install and
# provision LXD on your localhost for testing or if you want BCM running
# on your laptop/desktop. It basically allows BCM to treat your localhost
# like a remote ssh endpoint.
BCM_SSHD_START_FLAG='###START_BCM###'
SSH_CONFIG=/etc/ssh/sshd_config
if [[ -f "$SSH_CONFIG" ]]; then
    if ! grep -Fxq "$BCM_SSHD_START_FLAG" "$SSH_CONFIG"; then
        echo "$BCM_SSHD_START_FLAG" | sudo tee -a "$SSH_CONFIG"
        echo "ListenAddress 127.0.1.1" | sudo tee -a "$SSH_CONFIG"
        sudo systemctl restart ssh
    fi
fi

# this section configured the local SSH client on the Controller
# so it uses the local SOCKS5 proxy for any SSH host that has a
# ".onion" address. We use SSH tunneling to expose the remote onion
# server's LXD API and access it on the controller via a locally
# expose port (after SSH tunneling)
SSH_LOCAL_CONF="$SSH_DIR/config"

# if the .ssh/config file doesn't exist, create it.
if [[ ! -f "$SSH_LOCAL_CONF" ]]; then
    mkdir -p "$SSH_DIR"
    touch "$SSH_LOCAL_CONF"
fi

# Next, paste in the necessary .ssh/config settings for accessing
# remote LXD servers over TOR hidden services.
if [[ -f "$SSH_LOCAL_CONF" ]]; then
    SSH_ONION_TEXT="Host *.onion"
    if grep -Fxq "$SSH_ONION_TEXT" "$SSH_LOCAL_CONF"; then
        echo "$SSH_DIR/config already configured correctly."
    else
        {
            echo "$SSH_ONION_TEXT"
            echo "    ProxyCommand nc -xlocalhost:9050 -X5 %h %p"
        } >> "$SSH_LOCAL_CONF"
    fi
fi

echo "Done setting up your machine to use the Bitcoin Cache Machine CLI."
echo "Log out and log back in to refresh your group membership then open "
echo "a new terminal and type 'bcm --help'."
