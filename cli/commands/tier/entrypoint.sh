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
        *)
            # unknown option
        ;;
    esac
done


TIER_NAME=${3:-}
if [[ -z ${TIER_NAME} ]]; then
    echo "Please specify a BCM tier."
    cat ./help.txt
    exit
fi

# shellcheck disable=1090
source "$BCM_GIT_DIR/controller/export_usb_path.sh"

if [[ ! -z $BCM_TREZOR_USB_PATH ]]; then
    if [[ $BCM_CLI_VERB == "create" ]]; then
        bash -c "$BCM_GIT_DIR/project/tiers/up.sh --$TIER_NAME"
        
        elif [[ $BCM_CLI_VERB == "destroy" ]]; then
        bash -c "$BCM_GIT_DIR/project/tiers/destroy.sh --$TIER_NAME"
    else
        cat ./help.txt
    fi
fi