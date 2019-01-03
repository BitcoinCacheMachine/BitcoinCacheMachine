#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/.env"
# shellcheck disable=SC1090
source "$BCM_CERTS_DIR/.env"

# This is where we will store our GPG-encrypted passwords.
if [ ! -d "$BCM_PASSWORDS_DIR" ]; then
	bash -c "$BCM_GIT_DIR/cli/commands/git_init_dir.sh $BCM_PASSWORDS_DIR"
fi

# let's call bcm pass init to initialze the password store using our
# recently generated trezor-backed GPG certificates.
#shellcheck disable=SC1091
source ./export_usb_path.sh

# initialize the password store
docker run -it --name pass --rm -v "$BCM_CERTS_DIR":/root/.gnupg \
	-v "$BCM_PASSWORDS_DIR":/root/.password-store \
	-e BCM_CERT_NAME="$BCM_CERT_NAME" \
	-e BCM_CERT_USERNAME="$BCM_CERT_USERNAME" \
	-e BCM_CERT_FQDN="$BCM_CERT_FQDN" \
	--device="$BCM_TREZOR_USB_PATH" \
	bcm-trezor:latest pass init "$BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_FQDN>"

# # initialize the password store
# docker run -it --name pass --rm -v "$BCM_CERTS_DIR":/root/.gnupg \
# -v "$BCM_PASSWORDS_DIR":/root/.password-store \
# bcm-trezor:latest bash -c "git config --global user.name test && git config --global user.email test@test.com && pass git init"
