#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if [[ -z $BCM_SSH_USERNAME ]]; then
	echo "BCM_SSH_USERNAME empty."
	BCM_HELP_FLAG=1
fi

if [[ -z $BCM_SSH_HOSTNAME ]]; then
	echo "BCM_SSH_HOSTNAME empty."
	BCM_HELP_FLAG=1
fi

if [[ $BCM_HELP_FLAG == 1 ]]; then
	cat ./help.txt
	exit
fi

# get the locatio of the trezor
# shellcheck disable=1090
source "$BCM_GIT_DIR/controller/export_usb_path.sh"
echo "BCM_USB_PATH: $BCM_USB_PATH"
echo "BCM_SSH_KEY_DIR: $BCM_SSH_KEY_DIR"
echo "BCM_SSH_HOSTNAME: $BCM_SSH_HOSTNAME"
echo "BCM_SSH_USERNAME: $BCM_SSH_USERNAME"

if [[ ! -z $BCM_TREZOR_USB_PATH ]]; then
	docker run -t --rm \
		-v "$BCM_SSH_KEY_DIR":/root/.ssh \
		-e BCM_SSH_USERNAME="$BCM_SSH_USERNAME" \
		-e BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME" \
		--device="$BCM_TREZOR_USB_PATH" \
		bcm-trezor:latest bash -c "trezor-agent $BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME > /root/.ssh/$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME.pub"
fi

PUB_KEY="$BCM_SSH_KEY_DIR/$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME.pub"
if [[ -f "$PUB_KEY" ]]; then
	echo "Congratulations! Your new SSH public key can be found at '$PUB_KEY'"
else
	echo "ERROR: SSH Key did not generate successfully!"
fi
