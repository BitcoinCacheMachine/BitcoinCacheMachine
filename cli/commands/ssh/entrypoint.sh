#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# BCM_CLI_VERB=$2
BCM_SSH_USERNAME=
BCM_SSH_HOSTNAME=
BCM_CERT_DIR=
BCM_SSH_KEY_DIR=

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
	--ssh-key-dir=*)
		BCM_SSH_KEY_DIR="${i#*=}"
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

if [[ -z $BCM_SSH_KEY_DIR ]]; then
	echo "BCM_SSH_KEY_DIR is empty. Setting to $HOME/.ssh"
	export BCM_SSH_KEY_DIR="$HOME/.ssh"
fi

export BCM_SSH_USERNAME=$BCM_SSH_USERNAME
export BCM_SSH_HOSTNAME=$BCM_SSH_HOSTNAME
export BCM_SSH_KEY_DIR=$BCM_SSH_KEY_DIR

if [[ $BCM_CLI_VERB == "newkey" ]]; then
	./newkey/newkey.sh
elif [[ $BCM_CLI_VERB == "connect" ]]; then
	./connect/connect.sh
else
	cat ./help.txt
fi
