#!/bin/bash

set -eu
cd "$(dirname "$0")"

BCM_TREZOR_USB_PATH=
source $BCM_LOCAL_GIT_REPO/mgmt_plane/export_usb_path.sh
if [[ -z $BCM_TREZOR_USB_PATH ]]; then
    exit
else
    echo $BCM_TREZOR_USB_PATH
fi