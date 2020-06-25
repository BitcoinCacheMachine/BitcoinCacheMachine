#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE=${2:-}
if [ -n "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a SSH command."
    cat ./help.txt
    exit
fi

INPUT_FILE_PATH=
OUTPUT_DIR=

for i in "$@"; do
    case $i in
        --file=*)
            INPUT_FILE_PATH="${i#*=}"
            shift
        ;;
        --output-dir=*)
            OUTPUT_DIR="${i#*=}"
            shiftalue
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

if [[ -z "$INPUT_FILE_PATH" ]]; then
    echo "INPUT_FILE_PATH not set."
    cat ./help.txt
    exit
fi

if [[ ! -f "$INPUT_FILE_PATH" ]]; then
    echo "$INPUT_FILE_PATH does not exist. Exiting."
    cat ./help.txt
    exit
fi

if [[ ! -d "$OUTPUT_DIR" ]]; then
    echo "$OUTPUT_DIR does not exist. Exiting."
    exit
fi

INPUT_DIR=$(dirname $INPUT_FILE_PATH)
INPUT_FILE_NAME=$(basename $INPUT_FILE_PATH)

if [[ $BCM_CLI_VERB == "encrypt" ]]; then
    # start the container / trezor-gpg-agent
    docker run -it --rm --name trezorencryptor \
    -v "$GNUPGHOME":/home/user/.gnupg \
    -v "$INPUT_DIR":/inputdir \
    -v "$OUTPUT_DIR":/outputdir \
    "bcm-trezor:$BCM_VERSION" gpg --output "/inputdir/$INPUT_FILE_NAME.gpg" --encrypt --armor --recipient "$DEFAULT_KEY_ID" "/outputdir/$INPUT_FILE_NAME"
    
    if [[ -f "$INPUT_FILE_PATH.gpg" ]]; then
        echo "Encrypted file created at $INPUT_FILE_PATH.gpg"
        
        # if [[ $DELETE_INPUT_FILE_FLAG == 1 ]]; then
        #     rm "$INPUT_FILE_PATH"
        # fi
    fi
    
    elif [[ $BCM_CLI_VERB == "decrypt" ]]; then
    ./decrypt/decrypt.sh "$@"
    elif [[ $BCM_CLI_VERB == "createsignature" ]]; then
    ./create_signature/create_signature.sh "$@"
    elif [[ $BCM_CLI_VERB == "verifysignature" ]]; then
    ./verify_signature/verify_signature.sh "$@"
else
    cat ./help.txt
fi
