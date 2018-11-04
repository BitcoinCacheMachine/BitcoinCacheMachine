#!/bin/bash

set -eu

cd "$(dirname "$0")"

# this is the directory that we're going to emit public key material; should be backed up
BCM_CERT_DIR=$1

# The certs uid displays as:  "$BCM_CERT_NAME <BCM_CERT_USERNAME@BCM_CERT_HOSTNAME>"
BCM_CERT_NAME=$2
BCM_CERT_USERNAME=$3
BCM_CERT_HOSTNAME=$4

docker build -t bcm-trezor:latest $BCM_LOCAL_GIT_REPO/mgmt_plane/

source ./export_usb_path.sh

echo "BCM_CERT_DIR: $BCM_CERT_DIR"
echo "BCM_CERT_NAME: $BCM_CERT_NAME"
echo "BCM_CERT_USERNAME: $BCM_CERT_USERNAME"
echo "BCM_CERT_HOSTNAME: $BCM_CERT_HOSTNAME"
echo "BCM_TREZOR_USB_PATH: $BCM_TREZOR_USB_PATH"

# TODO move this into the mgmtplan container rather than installing on host.
bash -c "$BCM_LOCAL_GIT_REPO/cluster/providers/lxd/snap_lxd_install.sh"

# run the container.
docker run -it --name trezorgpg --rm -v $BCM_CERT_DIR:/root/.gnupg \
    -e BCM_CERT_NAME="$BCM_CERT_NAME" \
    -e BCM_CERT_USERNAME="$BCM_CERT_USERNAME" \
    -e BCM_CERT_HOSTNAME="$BCM_CERT_HOSTNAME" \
    --device=$BCM_TREZOR_USB_PATH \
    bcm-trezor:latest bash -c 'trezor-gpg init "$BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_HOSTNAME>"'

echo "Your public key and public keyring material can be found at '$BCM_CERT_DIR/trezor'."

export GNUPGHOME=$BCM_CERT_DIR/trezor

LINE=$(sudo GNUPGHOME="$GNUPGHOME" su -p root -c 'gpg --no-permission-warning --list-keys --keyid-format LONG | grep nistp256 | grep pub | sed 's/^[^/]*:/:/'')
echo $LINE
LINE="${LINE#*/}"
echo $LINE
LINE="$(echo $LINE | grep -o '^\S*')"
LINE="$(echo $LINE | xargs)"
touch $BCM_CERT_DIR/.env
echo '#!/bin/bash' >> "$BCM_CERT_DIR/.env"
echo "export BCM_DEFAULT_KEY_ID="'"'$LINE'"' >> "$BCM_CERT_DIR/.env"
echo "export BCM_CERT_NAME="'"'$BCM_CERT_NAME'"' >> "$BCM_CERT_DIR/.env"
echo "export BCM_CERT_USERNAME="'"'$BCM_CERT_USERNAME'"' >> "$BCM_CERT_DIR/.env"
echo "export BCM_CERT_HOSTNAME="'"'$BCM_CERT_HOSTNAME'"' >> "$BCM_CERT_DIR/.env"
