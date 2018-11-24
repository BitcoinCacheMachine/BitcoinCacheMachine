#!/usr/bin/env bash

set -Eeuo pipefail

NEW_USB_BASELINE=
export BCM_TREZOR_USB_PATH=

FLAG=0
NEW_USB_BASELINE=$(lsusb -d 0x1209:0x53c1 | xargs) || true

while [ -z "$NEW_USB_BASELINE" ]
do
    if [[ $FLAG = 0 ]]; then
        echo "Waiting for Trezor USB device. Ensure your Trezor is plugged in AND you have successfully entered your PIN."
        FLAG=1
    fi

    sleep .5
    printf '.'

    NEW_USB_BASELINE=$(lsusb -d 0x1209:0x53c1 | xargs) || true
done


if [[ ! -z "$NEW_USB_BASELINE" ]]; then
    # get 2nd word in output, which is the BUS
    NEW_USB_BUS=$(echo "$NEW_USB_BASELINE" | awk  '{print $2}')
    NEW_USB_DEVICE=$(echo "$NEW_USB_BASELINE" | awk  '{print $4}' | cut -c 1-3 )
    export BCM_TREZOR_USB_PATH="/dev/bus/usb/$NEW_USB_BUS/$NEW_USB_DEVICE"
fi