#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if [[ $BCM_HELP_FLAG == 1 ]]; then
    cat ./init-help.txt
    exit
fi

if [[ -z $BCM_CERT_NAME ]]; then
    echo "BCM_CERT_NAME not set."
    exit
fi

if [[ -z $BCM_CERT_USERNAME ]]; then
    echo "BCM_CERT_USERNAME not set."
    exit
fi

if [[ -z $BCM_CERT_HOSTNAME ]]; then
    echo "BCM_CERT_HOSTNAME not set."
    exit
fi

# shellcheck disable=SC2153
bash -c "$BCM_GIT_DIR/cli/commands/git_init_dir.sh $GNUPGHOME"

bash -c "$BCM_GIT_DIR/controller/gpg-init.sh \
    --dir='$GNUPGHOME' \
    --name='$BCM_CERT_NAME' \
    --username='$BCM_CERT_USERNAME' \
--hostname='$BCM_CERT_HOSTNAME'"

# now let's initialize the password repository with the GPG key
bcm pass init --name="$BCM_CERT_NAME" --username="$BCM_CERT_USERNAME" --hostname="$BCM_CERT_HOSTNAME"