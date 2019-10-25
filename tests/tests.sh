#!/bin/bash

# this is the entrypoint in to the testing framework for BCM.
# all test cases are executed against a fresh bionic instance (VM) using multipass
if [[ ! -f "$(command -v multipass)" ]]; then
    # install lxd via snap
    # unless this is modified, we get snapshot creation in snap when removing lxd.
    echo "INFO: Installing 'multipass' on $HOSTNAME."
    sudo snap install --edge --classic multipass
    sleep 5
fi

multipass launch --disk="20GB" --mem="4098MB" --cpus="4" --name="bcm" bionic

multipass mount "$HOME/.gnupg" bcm:/home/ubuntu/.gnupg

multipass connect bcm

curl https://raw.githubusercontent.com/BitcoinCacheMachine/BitcoinCacheMachine/dev/resources/git_init.sh | bash -
