#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_TREZOR_USB_PATH=
source $BCM_LOCAL_GIT_REPO_DIR/controller/export_usb_path.sh
if [[ -z $BCM_TREZOR_USB_PATH ]]; then
    exit
else
    echo $BCM_TREZOR_USB_PATH
fi