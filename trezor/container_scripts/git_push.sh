#!/bin/bash

echo "We're going to push the repo over TOR."

echo "Starting tor in the background."
service tor start 

wait-for-it -t 0 127.0.0.1:9050

git config --global http.proxy socks5://127.0.0.1:9050
echo "git config --global http.proxy:  $(git config --global --get http.proxy)"



### goal here is to do SSH authentication using trezor to remote repository, all over TOR.
git push origin dev


service tor stop