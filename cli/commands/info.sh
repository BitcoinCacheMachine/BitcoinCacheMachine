#!/bin/bash


set -eu
cd "$(dirname "$0")"

TREZOR_USB_PATH=$(bash -c ./shared/get_trezor_usb_path.sh)
echo "TREZOR_USB_PATH: $TREZOR_USB_PATH"