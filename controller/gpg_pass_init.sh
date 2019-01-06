#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/.env"

# This is where we will store our GPG-encrypted passwords.
if [ ! -d "$PASSWORD_STORE_DIR" ]; then
	bash -c "$BCM_GIT_DIR/cli/commands/git_init_dir.sh $PASSWORD_STORE_DIR"
fi

# let's call bcm pass init to initialze the password store using our
# recently generated trezor-backed GPG certificates.
#shellcheck disable=SC1091
source ./export_usb_path.sh

# initialize the password store
docker run -it --name pass --rm -v "$GNUPGHOME":/root/.gnupg \
	-v "$PASSWORD_STORE_DIR":/root/.password-store \
	-e BCM_CERT_NAME="$BCM_CERT_NAME" \
	-e BCM_CERT_USERNAME="$BCM_CERT_USERNAME" \
	-e BCM_CERT_HOSTNAME="$BCM_CERT_HOSTNAME" \
	--device="$BCM_TREZOR_USB_PATH" \
	bcm-trezor:latest pass init "$BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_HOSTNAME>"
