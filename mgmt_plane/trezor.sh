#!/bin/bash

set -e

# run this file using the following syntax:
#./trezor.sh -c gpg -o createfilesignature -f ~/.bcm/temp/temp1 -b $BCM_PROJECT_DIR
#./trezor.sh -c gpg -o verifyfilesig -f ~/.bcm/temp/temp1 -b $BCM_PROJECT_DIR
#./trezor.sh -c gpg -o encryptfile -f ~/.bcm/temp/temp1 -b $BCM_PROJECT_DIR
#./trezor.sh -c gpg -o decryptfile -f ~/.bcm/temp/temp1.gpg -b $BCM_PROJECT_DIR

## SSH
#./trezor.sh -c ssh -o newkey -u username -h github.com
#./trezor.sh -c ssh -o connect -u username -h github.com

# git
#./trezor.sh -c git -o commitsign -u username -h github.com

source $BCM_LOCAL_GIT_REPO/resources/export_bcm_envs.sh
# let's the arguments passed in on the terminal
# member count is really the number of nodes BEYOND the first cluster member.

while getopts c:o:f:b:u:h:s:m:g:x:e: option
do
    case "${option}"
    in
    c) export BCM_TREZOR_COMMAND=${OPTARG};;
    o) export BCM_TREZOR_OPERATION=${OPTARG};;
    f) export BCM_TREZOR_FILE_PATH=${OPTARG};;
    b) export BCM_PROJECT_DIR=${OPTARG};;
    u) export BCM_TREZOR_SSH_USERNAME=${OPTARG};;
    h) export BCM_TREZOR_SSH_HOSTNAME=${OPTARG};;
    s) export BCM_TREZOR_SSH_AUTHORIZED_KEYS_DIR=${OPTARG};;
    g) export BCM_GIT_REPO_DIR=${OPTARG};;
    m) export BCM_GIT_COMMIT_MESSAGE=${OPTARG};;
    x) export BCM_GIT_CLIENT_USERNAME=${OPTARG};;
    e) export BCM_PROJECT_CERTIFICATE_EMAIL=${OPTARG};;
    esac
done

source ./export_usb_path.sh

if [[ ! -z $BCM_TREZOR_USB_PATH ]]; then

    echo "BCM_CURRENT_PROJECT_NAME:  $BCM_CURRENT_PROJECT_NAME"
    echo "BCM_PROJECT_DIR: $BCM_PROJECT_DIR"

    if [[ $BCM_TREZOR_COMMAND = "gpg" ]]; then
        if [[ $BCM_TREZOR_OPERATION = "createfilesignature" ]]; then
            env BCM_TREZOR_FILE_PATH=$BCM_TREZOR_FILE_PATH BCM_PROJECT_DIR=$BCM_PROJECT_DIR BCM_TREZOR_USB_PATH=$BCM_TREZOR_USB_PATH bash -c "./commands/gpg/create_file_signature.sh"
        elif [[ $BCM_TREZOR_OPERATION = "verifyfilesig" ]]; then
            env BCM_TREZOR_FILE_PATH=$BCM_TREZOR_FILE_PATH BCM_PROJECT_DIR=$BCM_PROJECT_DIR bash -c "./commands/gpg/verify_file_signature.sh"
        elif [[ $BCM_TREZOR_OPERATION = "encryptfile" ]]; then
            
        elif [[ $BCM_TREZOR_OPERATION = "decryptfile" ]]; then
            env BCM_TREZOR_FILE_PATH=$BCM_TREZOR_FILE_PATH BCM_PROJECT_DIR=$BCM_PROJECT_DIR BCM_TREZOR_USB_PATH=$BCM_TREZOR_USB_PATH bash -c "./commands/gpg/decrypt_file.sh"
        fi
    elif [[ $BCM_TREZOR_COMMAND = "ssh" ]]; then
        
        # default to user's ~/.ssh/ folder for known_host management.
        if [[ -z $BCM_TREZOR_SSH_AUTHORIZED_KEYS_DIR ]]; then
            BCM_TREZOR_SSH_AUTHORIZED_KEYS_DIR=~/.ssh
        fi

        # trezor SSH keys are unique per BIP32/username@hostname tuple
        if [[ $BCM_TREZOR_OPERATION = "newkey" ]]; then
            # run the agent.
            mkdir -p $BCM_PROJECT_DIR/ssh
            env BCM_PROJECT_DIR=$BCM_PROJECT_DIR BCM_TREZOR_USB_PATH=$BCM_TREZOR_USB_PATH BCM_TREZOR_SSH_USERNAME=$BCM_TREZOR_SSH_USERNAME BCM_TREZOR_SSH_HOSTNAME=$BCM_TREZOR_SSH_HOSTNAME BCM_TREZOR_SSH_AUTHORIZED_KEYS_DIR=$BCM_TREZOR_SSH_AUTHORIZED_KEYS_DIR bash -c "./commands/ssh/newkey.sh"
        fi
    fi
else
    echo "Trezor not detected."
fi