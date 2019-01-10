#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE=${2:-}
if [ ! -z ${VALUE} ]; then
	BCM_CLI_VERB="$2"
else
	echo "Please provide a SSH command."
	cat ./help.txt
	exit
fi

BCM_SSH_USERNAME=
BCM_SSH_HOSTNAME=
BCM_SSH_PUSH=0

for i in "$@"; do
	case $i in
	--username=*)
		BCM_SSH_USERNAME="${i#*=}"
		shift # past argument=value
		;;
	--hostname=*)
		BCM_SSH_HOSTNAME="${i#*=}"
		shift # past argument=value
		;;
	--push)
		BCM_SSH_PUSH=1
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

if [[ -z $SSH_DIR ]]; then
	echo "SSH_DIR is empty. Setting to $HOME/.ssh"
	exit
fi

# shellcheck disable=1090
source "$BCM_GIT_DIR/controller/export_usb_path.sh"

export BCM_SSH_USERNAME="$BCM_SSH_USERNAME"
export BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME"
export SSH_DIR="$SSH_DIR"

if [[ ! -z $BCM_TREZOR_USB_PATH ]]; then

	if [[ $BCM_CLI_VERB == "newkey" ]]; then

		USER_HOSTNAME=${3:-}
		if [ ! -z ${USER_HOSTNAME} ]; then
			BCM_SSH_USERNAME=$(echo "$USER_HOSTNAME" | cut -d@ -f1)
			BCM_SSH_HOSTNAME=$(echo "$USER_HOSTNAME" | cut -d@ -f2)
		else
			echo "Provide the username & hostname:  user@host"
			cat ./help.txt
			exit
		fi
		if [[ -z $BCM_SSH_HOSTNAME ]]; then
			echo "BCM_SSH_HOSTNAME is empty."
			cat ./newkey/help.txt
			exit
		fi

		if [[ -z $BCM_SSH_USERNAME ]]; then
			echo "BCM_SSH_USERNAME is empty."
			cat ./newkey/help.txt
			exit
		fi

		# if they're both empty, let's check to see if they used the 'user@hostname' format instead.
		if [[ -z $BCM_SSH_USERNAME && -z $BCM_SSH_HOSTNAME ]]; then
			USER_HOSTNAME=${3:-}
			if [ ! -z ${USER_HOSTNAME} ]; then
				BCM_SSH_USERNAME=$(echo "$USER_HOSTNAME" | cut -d@ -f1)
				BCM_SSH_HOSTNAME=$(echo "$USER_HOSTNAME" | cut -d@ -f2)
			else
				echo "Provide the username & hostname:  user@host"
				cat ./help.txt
				exit
			fi
		fi

		docker run -t --rm \
			-v "$SSH_DIR":/root/.ssh \
			-e BCM_SSH_USERNAME="$BCM_SSH_USERNAME" \
			-e BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME" \
			--device="$BCM_TREZOR_USB_PATH" \
			bcm-trezor:latest bash -c "trezor-agent $BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME -v > /root/.ssh/$BCM_SSH_USERNAME""_""$BCM_SSH_HOSTNAME.pub"

		PUB_KEY="$SSH_DIR/$BCM_SSH_USERNAME""_""$BCM_SSH_HOSTNAME.pub"
		if [[ -f "$PUB_KEY" ]]; then
			echo "Congratulations! Your new SSH public key can be found at '$PUB_KEY'"

			# Push to desintion if specified.
			if [[ $BCM_SSH_PUSH == 1 ]]; then
				if [[ $BCM_SSH_HOSTNAME == *.onion ]]; then
					torify ssh-copy-id -f -i "$PUB_KEY" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME"
				else
					ssh-copy-id -f -i "$PUB_KEY" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME"
				fi
			fi
		else
			echo "ERROR: SSH Key did not generate successfully!"
		fi
	elif [[ $BCM_CLI_VERB == "connect" ]]; then

		USER_HOSTNAME=${3:-}
		if [ ! -z ${USER_HOSTNAME} ]; then
			BCM_SSH_USERNAME=$(echo "$USER_HOSTNAME" | cut -d@ -f1)
			BCM_SSH_HOSTNAME=$(echo "$USER_HOSTNAME" | cut -d@ -f2)
		else
			echo "Provide the username & hostname:  user@host"
			cat ./help.txt
			exit
		fi
		if [[ -z $BCM_SSH_HOSTNAME ]]; then
			echo "BCM_SSH_HOSTNAME is empty."
			cat ./newkey/help.txt
			exit
		fi

		if [[ -z $BCM_SSH_USERNAME ]]; then
			echo "BCM_SSH_USERNAME is empty."
			cat ./newkey/help.txt
			exit
		fi

		docker run -it --rm --add-host="$BCM_SSH_HOSTNAME:$(dig +short "$BCM_SSH_HOSTNAME")" \
			-v "$SSH_DIR":/root/.ssh \
			-e BCM_SSH_USERNAME="$BCM_SSH_USERNAME" \
			-e BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME" \
			--device="$BCM_TREZOR_USB_PATH" \
			bcm-trezor:latest bash -c "trezor-agent $BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME --connect --verbose"
	elif [[ $BCM_CLI_VERB == "list" ]]; then
		echo "SSH_DIR: $SSH_DIR"
		ls -lah "$SSH_DIR"
	else
		cat ./help.txt
	fi
fi
