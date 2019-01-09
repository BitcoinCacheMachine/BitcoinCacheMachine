#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# The certs uid displays as:  "$BCM_CERT_NAME <BCM_CERT_USERNAME@BCM_CERT_HOSTNAME>"
BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_HOSTNAME=

for i in "$@"; do
	case $i in
	--dir=*)
		GNUPGHOME="${i#*=}"
		shift # past argument=value
		;;
	--name=*)
		BCM_CERT_NAME="${i#*=}"
		shift # past argument=value
		;;
	--username=*)
		BCM_CERT_USERNAME="${i#*=}"
		shift # past argument=value
		;;
	--hostname=*)
		BCM_CERT_HOSTNAME="${i#*=}"
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

if ! docker image list --format "{{.Repository}}" | grep -q "bcm-trezor"; then
	bash -c "$BCM_GIT_DIR/controller/build.sh"
fi

echo "BCM_CERT_NAME: $BCM_CERT_NAME"
echo "BCM_CERT_USERNAME: $BCM_CERT_USERNAME"
echo "BCM_CERT_HOSTNAME: $BCM_CERT_HOSTNAME"

# get the locatio of the trezor
source ./export_usb_path.sh
BCM_TREZOR_USB_PATH="$(echo "$BCM_TREZOR_USB_PATH" | xargs)"
BCM_CERT_NAME="$(echo "$BCM_CERT_NAME" | xargs)"
BCM_CERT_HOSTNAME="$(echo "$BCM_CERT_HOSTNAME" | xargs)"

if [[ ! -z $BCM_TREZOR_USB_PATH ]]; then
	# run the container.
	docker run -it --name trezorgpg --rm \
		-v "$GNUPGHOME":/root/.gnupg \
		-e BCM_CERT_NAME="$BCM_CERT_NAME" \
		-e BCM_CERT_USERNAME="$BCM_CERT_USERNAME" \
		-e BCM_CERT_HOSTNAME="$BCM_CERT_HOSTNAME" \
		--device="$BCM_TREZOR_USB_PATH" \
		bcm-trezor:latest trezor-gpg init "$BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_HOSTNAME>"

	echo "Your public key and public keyring material can be found at '$GNUPGHOME/trezor'."
fi

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
	echo "export BCM_CERT_HOSTNAME="'"'$BCM_CERT_HOSTNAME'"'
} >>"$GNUPGHOME/.env"
