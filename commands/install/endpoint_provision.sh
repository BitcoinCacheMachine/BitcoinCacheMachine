#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

YAML_TEXT=

for i in "$@"; do
    case $i in
        --yaml-text=*)
            YAML_TEXT="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

# echo "$YAML_TEXT" | sudo lxd init --preseed

# # all LXC operations use the local unix socket; BCM DOES NOT
# # employ HTTPS -based LXD. All management plane operations are
# # via SSH.
# lxc remote set-default "local"
