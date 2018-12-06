#!/usr/bin/env bash

NETWORK_NAME=

for i in "$@"; do
	case $i in
	--network-name=*)
		NETWORK_NAME="${i#*=}"
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

if [[ -z $NETWORK_NAME ]]; then
	echo "Error. NETWORK_NAME was empty."
	exit
fi

if lxc network list | grep -q "$NETWORK_NAME"; then
	lxc network delete "$NETWORK_NAME"
fi
