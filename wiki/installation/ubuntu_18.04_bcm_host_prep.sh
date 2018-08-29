#!/bin/bash

sudo apt-get update
sudo apt upgrade -y
sudo apt-get install lxd zfsutils -y

cat <<EOF | lxd init --preseed
# Daemon settings
config:
  core.https_address: '[::]:8443'
  core.trust_password: CHANGEME
  images.auto_update_interval: 6
EOF