#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/.env"
# shellcheck disable=SC1090
source "$BCM_CERTS_DIR/.env"

# This is where we will store our GPG-encrypted passwords.
if [ ! -d "$BCM_PASSWORDS_DIR" ]; then
	echo "Creating $BCM_PASSWORDS_DIR"
	mkdir -p "$BCM_PASSWORDS_DIR"
fi

# let's call bcm pass init to initialze the password store using our
# recently generated trezor-backed GPG certificates.
#shellcheck disable=SC1091
source ./export_usb_path.sh
docker run -it --name pass --rm \
	-v "$BCM_CERTS_DIR":/root/.gnupg \
	-v "$BCM_PASSWORDS_DIR":/root/.password-store \
	-e BCM_CERTIFICATE_NAME="$BCM_CERTIFICATE_NAME" \
	--device="$BCM_TREZOR_USB_PATH" \
	bcm-trezor:latest pass init "$BCM_CERTIFICATE_NAME"

# ok great, now we have it initialized. Let's create a new GPG-encrypted password
# file for the encfs mount on our controller machine. This allows us to encrypt the
# BCM files on disk using a password backed by the trezor.
BCM_PASS_ENCFS_PATH="bcm/controller/encfs"

bcm pass new --name=$BCM_PASS_ENCFS_PATH

if ! dpkg-query -s encfs | grep -q "Status: install ok installed"; then
	echo "Installing encfs which encrypts data written to disk."
	sudo apt-get install -y encfs
fi

if grep -q "#user_allow_other" </etc/fuse.conf; then
	# update /etc/fuse.conf to allow non-root users to specify the allow_root mount option
	sudo sed -i -e 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf
fi

mkdir -p "$BCM_RUNTIME_DIR/.encrypted"
mkdir -p "$BCM_RUNTIME_DIR/encrypted"

# 60 minute idle timeout in which case the encrypted mount will be unmounted
encfs -o allow_root "$BCM_RUNTIME_DIR/.encrypted" "$BCM_RUNTIME_DIR/encrypted" -i=60 --paranoia --extpass="bcm pass get --name=$BCM_PASS_ENCFS_PATH" >>/dev/null
echo "Created $BCM_RUNTIME_DIR/ on $(date -u "+%Y-%m-%dT%H:%M:%S %Z")." >"$BCM_RUNTIME_DIR/debug.log"
