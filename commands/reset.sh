#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

CONTINUE=0
CHOICE=n

if [[ $BCM_RUNTIME_DIR == "$HOME" ]]; then
    echo "WARNING: BCM reset will NOT run when 'bcmruntimedir=$HOME'"
    exit
fi

while [[ "$CONTINUE" == 0 ]]
do
    echo "WARNING: 'bcm reset' will delete the contents of '$BCM_RUNTIME_DIR' and will remove multipass, LXD, and docker from your localhost."
    read -rp "Are you sure you want to continue? (y/n):  "   CHOICE
    
    if [[ "$CHOICE" == "y" ]]; then
        CONTINUE=1
        elif [[ "$CHOICE" == "n" ]]; then
        exit
    else
        echo "Invalid entry. Please try again."
    fi
done

# never delete GNUPGHOME UNLESS if the CLI is set to HOME/.gnupg (ie must be under ~/.bcm)

if [[ -d "$GNUPGHOME" ]]; then
    if [[ $GNUPGHOME != "$HOME/.gnupg" ]]; then
        if [[ "$CHOICE" == 'y' ]]; then
            if [ "$GNUPGHOME" != "$HOME/.gnupg" ]; then
                echo "Deleting $GNUPGHOME."
                rm -Rf "$GNUPGHOME"
            fi
        fi
    fi
else
    echo "WARNING: GNUPGHOME directory '$GNUPGHOME' does not exist. You may need to run 'bcm init'."
fi

if [[ -d "$PASSWORD_STORE_DIR" ]]; then
    if [[ "$CHOICE" == 'y' ]]; then
        if [ "$PASSWORD_STORE_DIR" != "$HOME/.password_store" ]; then
            echo "Deleting $PASSWORD_STORE_DIR."
            rm -Rf "$PASSWORD_STORE_DIR"
        fi
    fi
else
    echo "WARNING: PASSWORD_STORE_DIR directory '$PASSWORD_STORE_DIR' does not exist. You may need to run 'bcm init'."
fi

if [[ -d "$ELECTRUM_DIR" ]]; then
    if [[ "$CHOICE" == 'y' ]]; then
        if [ "$ELECTRUM_DIR" != "$HOME/.electrum" ]; then
            # now let;s unmount the temp directory and remove the folders.
            encfs -u "$ELECTRUM_DIR">>/dev/null
            
            if [[ -d "$ELECTRUM_DIR" ]]; then
                echo "Removing $ELECTRUM_DIR"
                rm -rf "$ELECTRUM_DIR"
            fi
            
            if [[ -d "$ELECTRUM_ENC_DIR" ]]; then
                echo "Removing $ELECTRUM_ENC_DIR"
                rm -rf "$ELECTRUM_ENC_DIR"
            fi
        fi
    fi
else
    echo "WARNING: ELECTRUM_DIR directory '$ELECTRUM_DIR' does not exist. You may need to run 'bcm init'."
fi


if [[ -d "$BCM_WORKING_DIR" ]]; then
    # now let;s unmount the temp directory and remove the folders.
    encfs -u "$BCM_WORKING_DIR">>/dev/null
    
    echo "Removing $BCM_WORKING_DIR"
    rm -rf "$BCM_WORKING_DIR"
    
    if [[ -d "$BCM_WORKING_ENC_DIR" ]]; then
        echo "Removing $BCM_WORKING_ENC_DIR"
        rm -rf "$BCM_WORKING_ENC_DIR"
    fi
fi


if [[ -d "$BCM_SSH_DIR" ]]; then
    if [[ "$CHOICE" == 'y' ]]; then
        if [ "$BCM_SSH_DIR" != "$HOME/.ssh" ]; then
            echo "Deleting $BCM_SSH_DIR."
            rm -Rf "$BCM_SSH_DIR"
        fi
    fi
else
    echo "WARNING: BCM_SSH_DIR directory '$BCM_SSH_DIR' does not exist. You may need to run 'bcm init'."
fi

if [[ -d "$BCM_WORKING_DIR" ]]; then
    if [[ "$CHOICE" == 'y' ]]; then
        # now let;s unmount the temp directory and remove the folders.
        encfs -u "$BCM_WORKING_DIR">>/dev/null
        
        if [[ -d "$BCM_WORKING_DIR" ]]; then
            echo "Removing $BCM_WORKING_DIR"
            rm -rf "$BCM_WORKING_DIR"
        fi
        
        if [[ -d "$BCM_WORKING_ENC_DIR" ]]; then
            echo "Removing $BCM_WORKING_ENC_DIR"
            rm -rf "$BCM_WORKING_ENC_DIR"
        fi
    fi
else
    echo "WARNING: BCM_WORKING_DIR directory '$BCM_WORKING_DIR' does not exist. You may need to run 'bcm init'."
fi

echo "Removing all BCM-related entries from /etc/hosts"
sudo sed -i "/bcm-/d" /etc/hosts

if [ -x "$(command -v multipass)" ]; then
    sudo snap remove multipass
else
    echo "Info: multipass was not installed."
fi

if [ -x "$(command -v lxc)" ]; then
    sudo lxd shutdown
    
    sudo snap remove lxd
else
    echo "Info: lxd was not installed."
fi

if [ -x "$(command -v docker)" ]; then
    sudo snap remove docker
else
    echo "Info: docker was not installed."
fi