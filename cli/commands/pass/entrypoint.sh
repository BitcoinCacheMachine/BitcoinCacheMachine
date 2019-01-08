#!/bin/bash

set -o nounset
cd "$(dirname "$0")"

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/.env"

BCM_CLI_VERB=
BCM_PASS_NAME=

VALUE=${2:-}
if [ ! -z "${VALUE}" ]; then
	BCM_CLI_VERB="$2"
else
	cat ./help.txt
	exit
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
		-v "$GNUPGHOME":/root/.gnupg:rw \
		-v "$PASSWORD_STORE_DIR":/root/.password-store:rw \
		-e BCM_PASS_NAME="$BCM_PASS_NAME" \
		--device="$BCM_TREZOR_USB_PATH" \
		bcm-trezor:latest bash -c "pass generate $BCM_PASS_NAME 32 >>/dev/null"

elif [[ $BCM_CLI_VERB == "init" ]]; then

	# This is where we will store our GPG-encrypted passwords.
	echo "PASSWORD_STORE_DIR: $PASSWORD_STORE_DIR"
	if [ ! -d "$PASSWORD_STORE_DIR" ]; then
		bash -c "$BCM_GIT_DIR/cli/commands/git_init_dir.sh $PASSWORD_STORE_DIR"
	fi

	# let's call bcm pass init to initialze the password store using our
	# recently generated trezor-backed GPG certificates.
	# shellcheck disable=SC1090
	source "$BCM_GIT_DIR/controller/export_usb_path.sh"

	# initialize the password store
	bcm info

	if [[ ! -f $GNUPGHOME/.env ]]; then
		echo "$GNUPGHOME/.env does not exist. Exiting"
		exit
	fi

	# shellcheck disable=SC1090
	source "$GNUPGHOME/.env"

	if [[ ! -d "$PASSWORD_STORE_DIR/.git" ]]; then
		cd "$PASSWORD_STORE_DIR"
		git init
		git config --local user.name "$BCM_CERT_USERNAME"
		git config --local user.email "$(whoami)@$BCM_CERT_HOSTNAME"
		touch debug.log
		echo "Created $PASSWORD_STORE_DIR/ on $(date -u "+%Y-%m-%dT%H:%M:%S %Z")." >"$PASSWORD_STORE_DIR/debug.log"
		git add "*"
		git commit -m "Initialized git repo."
		cd -
	fi

	# only run this if we don't have a .gpg-id file, which indicates it's
	# already been initialized
	if [[ ! -f "$GNUPGHOME/.gpg-id" ]]; then
		docker run -it --name pass --rm -v "$GNUPGHOME":/root/.gnupg \
			-v "$PASSWORD_STORE_DIR":/root/.password-store \
			-e BCM_CERT_NAME="$BCM_CERT_NAME" \
			-e BCM_CERT_USERNAME="$BCM_CERT_USERNAME" \
			-e BCM_CERT_HOSTNAME="$BCM_CERT_HOSTNAME" \
			--device="$BCM_TREZOR_USB_PATH" \
			bcm-trezor:latest pass init "$BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_HOSTNAME>"
	else
		echo "It appears as thought the password repo has already been initialized."
	fi
elif [[ $BCM_CLI_VERB == "get" ]]; then

	if [[ -z $BCM_PASS_NAME ]]; then
		echo "BCM_PASS_NAME cannot be empty. Use '--name=<password_name>'"
		cat ./help.txt
		exit
	fi

	# How we reference the password.
	docker run -it --name pass --rm \
		-v "$GNUPGHOME":/root/.gnupg:rw \
		-v "$PASSWORD_STORE_DIR":/root/.password-store \
		-e BCM_PASS_NAME="$BCM_PASS_NAME" \
		--device="$BCM_TREZOR_USB_PATH" \
		bcm-trezor:latest pass "$BCM_PASS_NAME"

elif [[ $BCM_CLI_VERB == "list" ]]; then
	# How we reference the password.
	docker run -it --name pass --rm \
		-v "$GNUPGHOME":/root/.gnupg:ro \
		-v "$PASSWORD_STORE_DIR":/root/.password-store \
		--device="$BCM_TREZOR_USB_PATH" \
		bcm-trezor:latest pass ls
elif [[ $BCM_CLI_VERB == "rm" ]]; then
	# How we reference the password.
	docker run -it --name pass --rm \
		-v "$GNUPGHOME":/root/.gnupg:rw \
		-v "$PASSWORD_STORE_DIR":/root/.password-store \
		-e BCM_PASS_NAME="$BCM_PASS_NAME" \
		--device="$BCM_TREZOR_USB_PATH" \
		bcm-trezor:latest pass rm "$BCM_PASS_NAME"

elif [[ $BCM_CLI_VERB == "insert" ]]; then
	# How we reference the password.
	docker run -it --name pass --rm \
		-v "$GNUPGHOME":/root/.gnupg:rw \
		-v "$PASSWORD_STORE_DIR":/root/.password-store \
		-e BCM_PASS_NAME="$BCM_PASS_NAME" \
		--device="$BCM_TREZOR_USB_PATH" \
		bcm-trezor:latest pass insert "$BCM_PASS_NAME"
fi
