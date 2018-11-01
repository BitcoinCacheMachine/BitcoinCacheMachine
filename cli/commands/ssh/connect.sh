#!/bin/bash

docker exec -it \
    -e BCM_TREZOR_SSH_USERNAME=$BCM_TREZOR_SSH_USERNAME \
    -e BCM_TREZOR_SSH_HOSTNAME=$BCM_TREZOR_SSH_HOSTNAME \
    bcmtrezorsshagent bash -c "trezor-agent $BCM_TREZOR_SSH_USERNAME@$BCM_TREZOR_SSH_HOSTNAME --connect --verbose"