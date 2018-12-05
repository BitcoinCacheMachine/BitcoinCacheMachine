#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source "$BCM_GIT_DIR/.env"

# The certs uid displays as:  "$BCM_CERT_NAME <BCM_CERT_USERNAME@BCM_CERT_FQDN>"
BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_FQDN=

for i in "$@"
do
case $i in
    --cert-dir=*)
    BCM_CERTS_DIR="${i#*=}"
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

# let's quit if they didn't pass the required arguments.
if [[ -z $BCM_CERT_NAME || -z $BCM_CERT_USERNAME || -z $BCM_CERT_FQDN ]]; then
    echo "You must set BCM_CERT_NAME, BCM_CERT_USERNAME, and BCM_CERT_FQDN"
fi

./build.sh
source ./export_usb_path.sh

echo "BCM_CERT_NAME: $BCM_CERT_NAME"
echo "BCM_CERT_USERNAME: $BCM_CERT_USERNAME"
echo "BCM_CERT_FQDN: $BCM_CERT_FQDN"

# TODO move this into the mgmtplan container rather than installing on host.
bash -c "$BCM_GIT_DIR/cluster/providers/lxd/snap_lxd_install.sh"
BCM_CERTIFICATE_NAME="$BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_FQDN>"

if [[ ! -z $BCM_TREZOR_USB_PATH ]]; then
    # run the container.
    docker run -it --name trezorgpg --rm \
        -v "$BCM_CERTS_DIR":/root/.gnupg \
        -e BCM_CERTIFICATE_NAME="$BCM_CERTIFICATE_NAME" \
        --device="$BCM_TREZOR_USB_PATH" \
        bcm-trezor:latest bash -c 'trezor-gpg init "$BCM_CERTIFICATE_NAME"'

    echo "Your public key and public keyring material can be found at '$BCM_CERTS_DIR/trezor'."
fi

export GNUPGHOME=$BCM_CERTS_DIR/trezor

# TODO move this to a container operation to avoid sudo
LINE=$(sudo GNUPGHOME="$GNUPGHOME" su -p root -c 'gpg --no-permission-warning --list-keys --keyid-format LONG | grep nistp256 | grep pub | sed 's/^[^/]*:/:/'')
#echo $LINE
LINE="${LINE#*/}"
#echo $LINE
LINE="$(echo "$LINE" | grep -o '^\S*')"
LINE="$(echo "$LINE" | xargs)"

{
    echo '#!/bin/bash'
    echo "export BCM_DEFAULT_KEY_ID="'"'"$LINE"'"'
    echo "export BCM_CERT_NAME="'"'$BCM_CERT_NAME'"'
    echo "export BCM_CERT_USERNAME="'"'$BCM_CERT_USERNAME'"'
    echo "export BCM_CERT_FQDN="'"'$BCM_CERT_FQDN'"' 
    echo "export BCM_CERTIFICATE_NAME='$BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_FQDN>'"
} >> "$BCM_CERTS_DIR/.env"
