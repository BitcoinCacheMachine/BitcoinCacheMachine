#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# # remove any pre-existing software that may exist and have conflicts.
# for PKG in lxd lxd-client; do
#     if dpkg -s "$PKG" >/dev/null 2>&1; then
#         while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
#             echo "Waiting for apt..."
#             sleep .5
#         done

#         apt-get remove -y "$PKG"
#     fi
# done

# reinstall required software.
apt-get install -y curl git apg snap snapd gnupg shred lxd

# if the lxd group doesn't exist, create it.
if ! grep -q lxd /etc/group; then
    addgroup --system lxd
fi

# add the SUDO_USER user to the lxd group
if ! groups | grep -q lxd; then
    usermod -G lxd -a "$SUDO_USER"
fi

# # install LXD
# if [[ ! -f "$(command -v lxc)" ]]; then
#     snap set system snapshots.automatic.retention=no
#     snap install lxd --channel="candidate"
# fi

export BCM_GIT_DIR="$(pwd)"
SUDO_USER_HOME="/home/$SUDO_USER"
bash -c "$BCM_GIT_DIR/commands/cluster/cluster_create.sh"

# # if there's no group called lxd, create it.
# if ! groups "$(whoami)" | grep -q lxd; then
#     gpasswd -a "$(whoami)" lxd
# fi

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

bash -c ./commands/cluster/cluster_create.sh
