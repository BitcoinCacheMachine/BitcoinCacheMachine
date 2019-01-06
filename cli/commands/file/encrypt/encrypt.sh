#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# start the container / trezor-gpg-agent
docker run -it --rm --name trezorencryptor \
	-v "$GNUPGHOME":/root/.gnupg \
	-v "$INPUT_FILE_DIR":/sigdir \
	bcm-trezor:latest gpg --output "/sigdir/$INPUT_FILE_NAME.gpg" --encrypt --recipient "$BCM_CERT_NAME" "/sigdir/$INPUT_FILE_NAME"

if [[ -f "$BCM_FILE_PATH.gpg" ]]; then
	echo "Encrypted file created at $BCM_FILE_PATH.gpg"
fi
