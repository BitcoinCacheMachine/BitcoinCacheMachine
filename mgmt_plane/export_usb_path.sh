#!/usr/bin/env bash

set -e

export TREZOR_USB_PATH=""
NEW_USB_BASELINE=
export BCM_TREZOR_USB_PATH=

checkTrezor() {
    # currentlt those hex nubmers are the vendor/product for the Trezor T. Need to find out if there are more of these combos that can be supported.
    NEW_USB_BASELINE=$(lsusb -d 0x1209:0x53c1 | xargs)
}

FLAG=0
for (( c=0; c<=1000; c++ ))
do  
   NEW_USB_BASELINE=$(lsusb -d 0x1209:0x53c1 | xargs)

    if [[ ! $(echo $NEW_USB_BASELINE | wc | awk '{print $2}') -eq 0 ]]; then
        # get 2nd word in output, which is the BUS
        NEW_USB_BUS=$(echo $NEW_USB_BASELINE | awk  '{print $2}')
        NEW_USB_DEVICE=$(echo $NEW_USB_BASELINE | awk  '{print $4}' | cut -c 1-3 )
        NEW_USB_ID=$(echo $NEW_USB_BASELINE | awk  '{print $6}' )
        export BCM_TREZOR_USB_PATH="/dev/bus/usb/$NEW_USB_BUS/$NEW_USB_DEVICE"
        break
    else
        if [[ $FLAG = 0 ]]; then
            echo "Waiting for Trezor USB device. Ensure your Trezor is plugged in AND you have successfully entered your PIN."
            FLAG=1
        fi

        sleep .5
        printf '.'
    fi
done
