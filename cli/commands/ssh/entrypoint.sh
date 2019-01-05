#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# BCM_CLI_VERB=$2
BCM_SSH_USERNAME=
BCM_SSH_HOSTNAME=
BCM_SSH_SCRIPT=

for i in "$@"; do
	case $i in
	--ssh-username=*)
		BCM_SSH_USERNAME="${i#*=}"
		shift # past argument=value
		;;
	--ssh-hostname=*)
		BCM_SSH_HOSTNAME="${i#*=}"
		shift # past argument=value
		;;
	--ssh-script=*)
		BCM_SSH_SCRIPT="${i#*=}"
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

if [[ -z $BCM_SSH_DIR ]]; then
	echo "BCM_SSH_DIR is empty. Setting to $HOME/.ssh"
	exit
fi

# shellcheck disable=1090
source "$BCM_GIT_DIR/controller/export_usb_path.sh"
echo "BCM_TREZOR_USB_PATH: $BCM_TREZOR_USB_PATH"
echo "BCM_SSH_DIR: $BCM_SSH_DIR"
echo "BCM_SSH_USERNAME: $BCM_SSH_USERNAME"
echo "BCM_SSH_HOSTNAME: $BCM_SSH_HOSTNAME"

export BCM_SSH_USERNAME="$BCM_SSH_USERNAME"
export BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME"
export BCM_SSH_DIR="$BCM_SSH_DIR"

if [[ ! -z $BCM_TREZOR_USB_PATH ]]; then
	if [[ $BCM_CLI_VERB == "newkey" ]]; then
		docker run -t --rm \
			-v "$BCM_SSH_DIR":/root/.ssh \
			-e BCM_SSH_USERNAME="$BCM_SSH_USERNAME" \
			-e BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME" \
			--device="$BCM_TREZOR_USB_PATH" \
			bcm-trezor:latest bash -c "trezor-agent $BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME -v > /root/.ssh/$BCM_SSH_USERNAME""_""$BCM_SSH_HOSTNAME.pub"

		PUB_KEY="$BCM_SSH_DIR/$BCM_SSH_USERNAME""_""$BCM_SSH_HOSTNAME.pub"
		if [[ -f "$PUB_KEY" ]]; then
			echo "Congratulations! Your new SSH public key can be found at '$PUB_KEY'"
		else
			echo "ERROR: SSH Key did not generate successfully!"
		fi
	elif [[ $BCM_CLI_VERB == "connect" ]]; then
		docker run -it --rm --add-host="$BCM_SSH_HOSTNAME:$(dig +short "$BCM_SSH_HOSTNAME")" \
			-v "$BCM_SSH_DIR":/root/.ssh \
			-e BCM_SSH_USERNAME="$BCM_SSH_USERNAME" \
			-e BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME" \
			--device="$BCM_TREZOR_USB_PATH" \
			bcm-trezor:latest bash -c "trezor-agent $BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME --connect --verbose"
	elif [[ $BCM_CLI_VERB == "execute" ]]; then
		if [[ ! -z $BCM_SSH_SCRIPT ]]; then
			if [[ -f $BCM_SSH_SCRIPT ]]; then
				echo "BCM_SSH_SCRIPT: '$BCM_SSH_SCRIPT'"

				docker run -it --rm --add-host="$BCM_SSH_HOSTNAME:$(dig +short "$BCM_SSH_HOSTNAME")" \
					-v "$BCM_SSH_DIR":/root/.ssh \
					-v "$BCM_SSH_SCRIPT":/root/script.sh \
					-e BCM_SSH_USERNAME="$BCM_SSH_USERNAME" \
					-e BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME" \
					--device="$BCM_TREZOR_USB_PATH" \
					bcm-trezor:latest bash -c "trezor-agent $BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME -c -v"

			fi
		fi
	else
		cat ./help.txt
	fi
fi
