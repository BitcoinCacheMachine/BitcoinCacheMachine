#!/bin/bash

set -eu

cd "$(dirname "$0")"

# this is the directory that we're going to emit public key material; should be backed up
BCM_CERT_DIR=

# The certs uid displays as:  "$BCM_CERT_NAME <BCM_CERT_USERNAME@BCM_CERT_FQDN>"
BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_FQDN=

for i in "$@"
do
case $i in
    --cert-dir=*)
    BCM_CERT_DIR="${i#*=}"
    shift # past argument=value
    ;;
    --cert-name=*)
    BCM_CERT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --cert-username=*)
    BCM_CERT_USERNAME="${i#*=}"
    shift # past argument=value
    ;;
    --cert-hostname=*)
    BCM_CERT_FQDN="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

./build.sh
source ./export_usb_path.sh

echo "BCM_CERT_DIR: $BCM_CERT_DIR"
echo "BCM_CERT_NAME: $BCM_CERT_NAME"
echo "BCM_CERT_USERNAME: $BCM_CERT_USERNAME"
echo "BCM_CERT_FQDN: $BCM_CERT_FQDN"

# TODO move this into the mgmtplan container rather than installing on host.
bash -c "$BCM_LOCAL_GIT_REPO_DIR/cluster/providers/lxd/snap_lxd_install.sh"

# get the locatio of the trezor
export BCM_TREZOR_USB_PATH=$(bcm info | grep "TREZOR_USB_PATH" | awk 'NF>1{print $NF}')

# run the container.
docker run -it --name trezorgpg --rm -v $BCM_CERT_DIR:/root/.gnupg \
    -e BCM_CERT_NAME="$BCM_CERT_NAME" \
    -e BCM_CERT_USERNAME="$BCM_CERT_USERNAME" \
    -e BCM_CERT_FQDN="$BCM_CERT_FQDN" \
    --device=$BCM_TREZOR_USB_PATH \
    bcm-trezor:latest bash -c 'trezor-gpg init "$BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_FQDN>"'

echo "Your public key and public keyring material can be found at '$BCM_CERT_DIR/trezor'."

export GNUPGHOME=$BCM_CERT_DIR/trezor

LINE=$(sudo GNUPGHOME="$GNUPGHOME" su -p root -c 'gpg --no-permission-warning --list-keys --keyid-format LONG | grep nistp256 | grep pub | sed 's/^[^/]*:/:/'')
#echo $LINE
LINE="${LINE#*/}"
#echo $LINE
LINE="$(echo $LINE | grep -o '^\S*')"
LINE="$(echo $LINE | xargs)"

echo '#!/bin/bash' > "$BCM_CERT_DIR/.env"
echo "export BCM_DEFAULT_KEY_ID="'"'$LINE'"' >> "$BCM_CERT_DIR/.env"
echo "export BCM_CERT_NAME="'"'$BCM_CERT_NAME'"' >> "$BCM_CERT_DIR/.env"
echo "export BCM_CERT_USERNAME="'"'$BCM_CERT_USERNAME'"' >> "$BCM_CERT_DIR/.env"
echo "export BCM_CERT_FQDN="'"'$BCM_CERT_FQDN'"' >> "$BCM_CERT_DIR/.env"
