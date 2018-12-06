#!/bin/bash

echo "We're going to pull the remote repo over TOR."

if [[ -z $BCM_REMOTE_REPO ]]; then
	echo "BCM_REMOTE_REPO was not set."
	exit
fi

echo "Starting tor in the background."
service tor start

wait-for-it -t 0 127.0.0.1:9050

sleep 10

git config --global "http.$BCM_REMOTE_REPO.proxy" socks5://127.0.0.1:9050

echo "git config --global http.$BCM_REMOTE_REPO.proxy:  $(git config --global --get "http.$BCM_REMOTE_REPO.proxy")"

### goal here is to do SSH authentication using trezor to remote repository, all over TOR.
git pull "$BCM_REMOTE_REPO" /gitrepo

service tor stop
