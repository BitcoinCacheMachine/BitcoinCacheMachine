#!/bin/bash

# this script loops through the lines in ./stack_options.csv which guide the script
# on which stacks to deploy.

set -eu

cd "$(dirname "$0")"

# arguments are "stack_name", "cert_cn/dns_name", and "tcpport"
bash -c ./registry_mirror/up_lxc_registrymirror.sh
bash -c ./private_registry/up_lxc_privateregistry.sh
bash -c ./squid/up_lxc_squid.sh
