#!/bin/bash


# git commit bcm
bcm git commit -g=/home/derek/git/github/forks/bcm -m='Updated CLI.' -i='farscapian' -o=/home/derek/certs/farscapiancom -e='derek@farscapian.com' -v='872406C8D1B52FF3'

# git commit WasabiWallet
bcm git commit -g=/home/derek/git/github/forks/WalletWasabi -m='Updated README.md to use TOR for git clone/pull.' -i='farscapian' -o=/home/derek/certs/farscapiancom -e='derek@farscapian.com' -v='872406C8D1B52FF3'


# create a multipass cluster
bcm cluster create -c=dev -t=multipass -l=3 -x=net



bcm init -n=test -u=ubuntu -c=domain.com

# create a 3 node multipass cluster locally.
bcm cluster create -c=home -t=multipass -l=3 -x=net


