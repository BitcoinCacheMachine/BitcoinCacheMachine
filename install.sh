#!/bin/bash

set -eu

echo "INFO: RUNNING BCM INSTALL SCRIPT"
echo "Current User: $USER"
echo "SUDO_USER:  $SUDO_USER"

# get the codename, usually bionic or debian
CODE_NAME="$(< /etc/os-release grep VERSION_CODENAME | cut -d "=" -f 2)"

# add the tor apt repository
echo "deb https://deb.torproject.org/torproject.org $CODE_NAME main" | tee -a /etc/apt/sources.list
echo "deb-src https://deb.torproject.org/torproject.org $CODE_NAME main" | tee -a /etc/apt/sources.list

# download the tor PGP key and add it as a trusted key to apt
curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

# update apt and install pre-reqs;
apt-get update

# remove any pre-existing software that may exist and have conflicts.
for PKG in lxd lxd-client tor; do
    if dpkg -s $PKG >/dev/null 2>&1; then
        apt-get remove "$PKG" -y
    fi
done

# remove any unused software.
apt-get autoremove -y

# reinstall required software.
apt-get install -y tor curl wait-for-it git deb.torproject.org-keyring iotop socat apg snapd openssh-server jq gnupg snapd

# upgrade all existing software.
# sudo apt-get upgrade -y

# wait for local tor to come online.
wait-for-it -t 30 127.0.0.1:9050

# configure git to download through the local tor proxy.
BCM_GITHUB_REPO_URL="https://github.com/BitcoinCacheMachine/BitcoinCacheMachine"
git config --global http.$BCM_GITHUB_REPO_URL.proxy socks5://127.0.0.1:9050

# clone the BCM repo to /home/$SUDO_USER/git/github/bcm
SUDO_USER_HOME="/home/$SUDO_USER"
BCM_GIT_DIR="$SUDO_USER_HOME/git/github/bcm"
if [[ ! -d $BCM_GIT_DIR ]]; then
    git clone "$BCM_GITHUB_REPO_URL" "$BCM_GIT_DIR"
else
    cd "$BCM_GIT_DIR" && git pull
fi

cd "$BCM_GIT_DIR" && git checkout dev

# let's make sure the local git client is using TOR for git pull operations.
# this should have been configured on a global level already when the user initially
# downloaded BCM from github
BCM_TOR_PROXY="socks5://127.0.0.1:9050"
if [[ "$(git config --get --local http.$BCM_GITHUB_REPO_URL.proxy)" != "$BCM_TOR_PROXY" ]]; then
    echo "Setting git client to use local SOCKS5 TOR proxy for push/pull operations."
    git config --local "http.$BCM_GITHUB_REPO_URL.proxy" "$BCM_TOR_PROXY"
fi

# install LXD
if [[ ! -f "$(command -v lxc)" ]]; then
    # install lxd via snap
    # unless this is modified, we get snapshot creation in snap when removing lxd.
    echo "INFO: Installing 'lxd' on $HOSTNAME."
    snap install lxd --channel="candidate"
    snap set system snapshots.automatic.retention=no
    sleep 5
fi

# if the lxd group doesn't exist, create it.
if ! grep -q lxd /etc/group; then
    addgroup --system lxd
fi

# add the SUDO_USER user to the lxd group
if ! groups | grep -q lxd; then
    usermod -G lxd -a "$SUDO_USER"
fi

# # if there's no group called lxd, create it.
# if ! groups "$(whoami)" | grep -q lxd; then
#     sudo gpasswd -a "$(whoami)" lxd
# fi

# TODO - update trusted PGP certificate.
# echo "GNUPGHOME: $GNUPGHOME"
# if ! gpg --list-keys | grep -q 94C6163354CB7A8CE5BABCDB36DB4B9E5F3E523C; then
#     echo "WARNING: the BCM public key will be imported into your local system. "
#     echo "INFO: bcm commands WILL NOT RUN unless you have explicitly trusted this key."
#     echo "INFO: run 'sudo gpg --import $BCM_GIT_DIR/PGP.txt' to import the BCM key."
#     exit
# fi

# configure SSH
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
# remote LXD servers over TOR hidden services. This will make any 'ssh' command
# redirect all .onion hostnames to your localhost:9050 tor SOCKS5 proxy.
if [[ -f "$SSH_LOCAL_CONF" ]]; then
    SSH_ONION_TEXT="Host *.onion"
    if ! grep -Fxq "$SSH_ONION_TEXT" "$SSH_LOCAL_CONF"; then
        echo "Info (IMPORTANT): Updating your /etc/ssh/sshd_config file so it redirects all *.onion names out your local Tor proxy."
        {
            echo "$SSH_ONION_TEXT"
            echo "    ProxyCommand nc -xlocalhost:9050 -X5 %h %p"
        } >>"$SSH_LOCAL_CONF"
    fi
fi


# # add the current user to the sudoers
# sudo touch "/etc/sudoers.d/$SUDO_USER"
# echo "$SUDO_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a "/etc/sudoers.d/$SUDO_USER"

# update /etc/ssh/sshd_config to listen for incoming SSH connections on all interfaces.
# TODO see if we can get this to listen on a specific interface rather than an IP address.
DEFAULT_ROUTE_INTERFACE="$(ip route | grep default | cut -d " " -f 5)"
IP_OF_DEFAULT_ROUTE_INTERFACE="$(ip addr show "$DEFAULT_ROUTE_INTERFACE" | grep "inet " | cut -d/ -f1 | awk '{print $NF}')"
if ! grep -Fxq "ListenAddress $IP_OF_DEFAULT_ROUTE_INTERFACE" /etc/ssh/sshd_config; then
    echo "ListenAddress $IP_OF_DEFAULT_ROUTE_INTERFACE" | tee -a /etc/ssh/sshd_config
fi


systemctl restart ssh
wait-for-it -t 15 "$IP_OF_DEFAULT_ROUTE_INTERFACE:22"
# end configure SSH
#####################

# install docker
if [[ ! -f "$(command -v docker)" ]]; then
    echo "INFO: Installing 'docker' locally using snap."
    snap install docker --channel="stable"
    sleep 2
    
    if ! grep -q docker /etc/group; then
        groupadd docker
    fi
    
    if ! groups "$SUDO_USER" | grep -q docker; then
        usermod -aG docker "$SUDO_USER"
    fi
    
    # next we need to determine the underlying file system so we can upload the correct daemon.json
    DEVICE="$(df -h "$HOME" | grep ' /' | awk '{print $1}')"
    FILESYSTEM="$(mount | grep "$DEVICE")"
    
    DAEMON_CONFIG="$BCM_GIT_DIR/commands/install/overlay_daemon.json"
    if echo "$FILESYSTEM" | grep -q "btrfs"; then
        DAEMON_CONFIG="$BCM_GIT_DIR/commands/install/btrfs_daemon.json"
        DEST_DAEMON_FILE="/var/snap/docker/current/config/daemon.json"
        echo "INFO: Setting dockerd daemon settings to $DEST_DAEMON_FILE"
        cp "$DAEMON_CONFIG" "$DEST_DAEMON_FILE"
        snap restart docker
    fi
fi

BASHRC_FILE="$SUDO_USER_HOME/.bashrc"
BASHRC_TEXT="export PATH=$""PATH:$SUDO_USER_HOME/git/github/bcm"
source "$BASHRC_FILE"
if ! grep -qF "$BASHRC_TEXT" "$BASHRC_FILE"; then
    echo "$BASHRC_TEXT" | tee -a "$BASHRC_FILE"
fi

echo "WARNING: Please restart your computer before running any 'bcm' commands!"
