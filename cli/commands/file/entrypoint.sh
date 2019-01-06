#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_FILE_PATH=
BCM_HELP_FLAG=0

for i in "$@"; do
	case $i in
	--file-path=*)
		BCM_FILE_PATH="${i#*=}"
		shift # past argument=value
		;;
	--help)
		BCM_HELP_FLAG=1
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

if [[ $BCM_HELP_FLAG == 1 ]]; then
	cat ./help.txt
	exit
fi

if [[ -z $BCM_FILE_PATH ]]; then
	echo "BCM_FILE_PATH not set."
	cat ./help.txt
	exit
fi

if [[ ! -f $BCM_FILE_PATH ]]; then
	echo "$BCM_FILE_PATH doesn't exist. Exiting."
	cat ./help.txt
	exit
fi

if [[ -z $BCM_FILE_PATH ]]; then
	echo "BCM_FILE_PATH not set."
	cat ./help.txt
	exit
fi

if [[ ! -d $GNUPGHOME ]]; then
	echo "$GNUPGHOME doesn't exist. Exiting."
	cat ./help.txt
	exit
fi

INPUT_FILE_DIR=
INPUT_FILE_NAME=

INPUT_FILE_DIR=$(dirname $BCM_FILE_PATH)
INPUT_FILE_NAME=$(basename $BCM_FILE_PATH)

export INPUT_FILE_DIR=$INPUT_FILE_DIR
export INPUT_FILE_NAME=$INPUT_FILE_NAME
export BCM_FILE_PATH=$BCM_FILE_PATH

if [[ $BCM_CLI_VERB == "encrypt" ]]; then
	./encrypt/encrypt.sh "$@"
elif [[ $BCM_CLI_VERB == "decrypt" ]]; then
	./decrypt/decrypt.sh "$@"
elif [[ $BCM_CLI_VERB == "createsignature" ]]; then
	./create_signature/create_signature.sh "$@"
elif [[ $BCM_CLI_VERB == "verifysignature" ]]; then
	./verify_signature/verify_signature.sh "$@"
else
	cat ./help.txt
fi
