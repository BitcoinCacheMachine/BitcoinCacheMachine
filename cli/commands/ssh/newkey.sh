#!/bin/bash

docker run -it --rm --name bcmtrezorsshagent \
    -v $BCM_PROJECT_DIR:/root/.gnupg \
    -v $BCM_TREZOR_SSH_AUTHORIZED_KEYS_DIR:/root/.ssh \
    --device="$BCM_TREZOR_USB_PATH" \
    bcm-trezor:latest bash -c "trezor-agent $BCM_TREZOR_SSH_USERNAME@$BCM_TREZOR_SSH_HOSTNAME > /root/.gnupg/mgmt_plane/ssh/id_rsa.pub && cat /root/.gnupg/mgmt_plane/ssh/id_rsa.pub >> /root/.ssh/known_hosts"