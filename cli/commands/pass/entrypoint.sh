#!/bin/bash

set -Eeo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/.env"

BCM_CLI_VERB=
BCM_PASS_NAME=

if [[ ! -z $2 ]]; then
	BCM_CLI_VERB=$2
fi

for i in "$@"; do
	case $i in
	--name=*)
		BCM_PASS_NAME="${i#*=}"
		shift # past argument=value
		;;
	*) ;;

	esac
done

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/controller/export_usb_path.sh"
if [[ $BCM_CLI_VERB == "new" ]]; then

	if [[ -z $BCM_PASS_NAME ]]; then
		echo "BCM_PASS_NAME cannot be empty. Use '--name=<password_name>'"
		cat ./help.txt
		exit
	fi

	# How we reference the password.
	docker run -it --name pass --rm \
		-v "$GNUPGHOME":/root/.gnupg \
		-v "$PASSWORD_STORE_DIR":/root/.password-store \
		-e BCM_PASS_NAME="$BCM_PASS_NAME" \
		--device="$BCM_TREZOR_USB_PATH" \
		bcm-trezor:latest bash -c "pass generate $BCM_PASS_NAME 32 >>/dev/null"

elif [[ $BCM_CLI_VERB == "get" ]]; then

	if [[ -z $BCM_PASS_NAME ]]; then
		echo "BCM_PASS_NAME cannot be empty. Use '--name=<password_name>'"
		cat ./help.txt
		exit
	fi

	# How we reference the password.
	docker run -it --name pass --rm \
		-v "$GNUPGHOME":/root/.gnupg \
		-v "$PASSWORD_STORE_DIR":/root/.password-store \
		-e BCM_PASS_NAME="$BCM_PASS_NAME" \
		--device="$BCM_TREZOR_USB_PATH" \
		bcm-trezor:latest pass "$BCM_PASS_NAME"
elif [[ $BCM_CLI_VERB == "list" ]]; then
	# How we reference the password.
	docker run -it --name pass --rm \
		-v "$GNUPGHOME":/root/.gnupg \
		-v "$PASSWORD_STORE_DIR":/root/.password-store \
		--device="$BCM_TREZOR_USB_PATH" \
		bcm-trezor:latest pass ls
elif [[ $BCM_CLI_VERB == "rm" ]]; then
	# How we reference the password.
	docker run -it --name pass --rm \
		-v "$GNUPGHOME":/root/.gnupg \
		-v "$PASSWORD_STORE_DIR":/root/.password-store \
		-e BCM_PASS_NAME="$BCM_PASS_NAME" \
		--device="$BCM_TREZOR_USB_PATH" \
		bcm-trezor:latest pass rm "$BCM_PASS_NAME"
elif [[ $BCM_CLI_VERB == "insert" ]]; then
	# How we reference the password.
	docker run -it --name pass --rm \
		-v "$GNUPGHOME":/root/.gnupg \
		-v "$PASSWORD_STORE_DIR":/root/.password-store \
		-e BCM_PASS_NAME="$BCM_PASS_NAME" \
		--device="$BCM_TREZOR_USB_PATH" \
		bcm-trezor:latest pass insert "$BCM_PASS_NAME"
fi
