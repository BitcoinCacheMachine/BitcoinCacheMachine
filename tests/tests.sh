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

multipass launch --disk="120GB" --mem="4098MB" --cpus="4" --name="bcm" bionic

multipass exec bcm -- curl https://raw.githubusercontent.com/BitcoinCacheMachine/BitcoinCacheMachine/resources/git_init.sh | sudo bash
