#!/bin/bash

set -Eeoux pipefail

# this is the entrypoint in to the testing framework for BCM.
# all test cases are executed against a fresh bionic instance (VM) using multipass
if [[ ! -f "$(command -v multipass)" ]]; then
    # install lxd via snap
    # unless this is modified, we get snapshot creation in snap when removing lxd.
    echo "INFO: Installing 'multipass' on $HOSTNAME."
    sudo snap install --edge --classic multipass
    sleep 5
fi


if ! multipass list | grep -q bcm; then
    multipass launch --disk="30GB" --mem="4098MB" --cpus="4" --name="bcm" bionic
fi

multipass exec bcm -- wget --output-document=bcm_init.sh https://raw.githubusercontent.com/BitcoinCacheMachine/BitcoinCacheMachine/dev/resources/bcm_init.sh >>/dev/null
multipass exec bcm -- chmod 0744 bcm_init.sh
multipass exec bcm -- bash -c bcm_init.sh

multipass exec bcm -- bcm stack start bitcoind
