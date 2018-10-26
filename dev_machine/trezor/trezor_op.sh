#!/bin/bash

# this script signs an arbitrary file and spits out a corresponding .sig file in the same directory
# Using Trezor for signing oeprations.
cd "$(dirname "$0")"

source $BCM_LOCAL_GIT_REPO/resources/export_bcm_envs.sh

COMMAND=$1
OPERATION=$2
FILE_PATH=$3
BCM_CERT_DIR=$GNUPGHOME

if [[ -z $OPERATION ]]; then
    echo "$OPERATION can't be empty."
    exit
fi

# ensure we have a BCM_CURRENT_PROJECT_NAME
if [[ -z $BCM_CURRENT_PROJECT_NAME ]]; then
    echo "BCM_CURRENT_PROJECT_NAME not set. Exiting"
    exit
fi

# ensure we the BCM_CERT_DIR is valid.
if [[ -z $4 ]]; then
    BCM_CERT_DIR=$4
fi

# BCM_GIT_COMMIT_MESSAGE must be set.
if [[ -z $BCM_GIT_COMMIT_MESSAGE ]]; then
    echo "BCM_GIT_COMMIT_MESSAGE is not set. Exiting"
    exit
fi

# select on which command we're doing.
if [[ $COMMAND = "gpg" ]]; then
    # let's check that the file exists.
    if [[ ! -f $FILE_PATH ]]; then
        echo "FILE_PATH '$FILE_PATH' does not exist."
        exit
    fi

    export INPUT_FILE_NAME=$(basename $FILE_PATH)
    export INPUT_FILE_DIR=$(dirname $FILE_PATH)

    # for those operations not requiring the trezor
    if [[ $OPERATION = "verify" ]]; then
        echo "BCM Project cert path: $BCM_CERT_DIR"
        echo "File to be verified: $INPUT_FILE_DIR"
        echo "Signature file: $INPUT_FILE_NAME.sig"
        docker run -it -v $BCM_CERT_DIR:/root/.gnupg/trezor \
            -v $INPUT_FILE_DIR:/sigdir \
            bcmtrezor:latest gpg --verify /sigdir/$INPUT_FILE_NAME.sig /sigdir/$INPUT_FILE_NAME

    elif [[ $OPERATION = "encrypt" ]]; then
        echo "BCM Project cert path: $BCM_CERT_DIR"
        echo "File to encrypt: $INPUT_FILE_NAME"
        docker run -it -v $BCM_CERT_DIR:/root/.gnupg/trezor \
            -v $INPUT_FILE_DIR:/sigdir \
            bcmtrezor:latest gpg --output /sigdir/$INPUT_FILE_NAME.gpg --encrypt --recipient $BCM_CURRENT_PROJECT_NAME /sigdir/$INPUT_FILE_NAME

        if [[ -f $FILE_PATH.gpg ]]; then
            echo "Encrypted file created at $FILE_PATH.gpg"
        fi
    else
        # for operations that require a Trezor; signing and decryption
        source $BCM_LOCAL_GIT_REPO/dev_machine/trezor/export_usb_path.sh
        if [[ ! -z $TREZOR_USB_PATH ]]; then
            echo "Trezor USB Path: $TREZOR_USB_PATH"
            
            if [[ $OPERATION = "sign" ]]; then
                echo "Signature file to be created: $FILE_PATH.sig"
                # will pgp sign a file uwing your trezor
                docker run -it -v $BCM_CERT_DIR:/root/.gnupg/trezor \
                    -v $INPUT_FILE_DIR:/sigdir \
                    --device=$TREZOR_USB_PATH \
                    bcmtrezor:latest gpg --sign --detach-sig -s /sigdir/$INPUT_FILE

                if [[ -f $FILE_PATH.sig ]]; then
                    echo "Signature created at $FILE_PATH.sig"
                fi
        
            elif [[ $OPERATION = "decrypt" ]]; then
                echo "Attempting to decrypt $FILE_PATH.gpg"

                docker run -it \
                    -v $BCM_CERT_DIR:/root/.gnupg/trezor \
                    -v $INPUT_FILE_DIR:/sigdir \
                    --device=$TREZOR_USB_PATH \
                    bcmtrezor:latest gpg --output /sigdir/$INPUT_FILE_NAME.decrypted --decrypt /sigdir/$INPUT_FILE_NAME
            fi
        fi
    fi
elif [[ $COMMAND = "git" ]]; then
    if [[ $OPERATION = "commit" ]]; then
        echo "Attempting to perform a git commit of the '$FILE_PATH' repo, signing with key material in '$BCM_CERT_DIR'."
        
        # for operations that require a Trezor; signing and decryption        
        source $BCM_LOCAL_GIT_REPO/dev_machine/trezor/export_usb_path.sh
        if [[ ! -z $TREZOR_USB_PATH ]]; then
            echo "Trezor USB Path: $TREZOR_USB_PATH"

            if [[ ! -z $(docker ps | grep bcmtrezoragent) ]]; then
                docker kill bcmtrezoragent
                sleep 2
                docker system prune -f
            fi

            docker run -d --name bcmtrezoragent \
                -v $BCM_CERT_DIR:/root/.gnupg/trezor \
                -v $FILE_PATH:/gitrepo \
                --device="$TREZOR_USB_PATH" \
                bcmtrezor:latest
            
            sleep 2

            echo "Attempting to use trezor to commit and sign the git repo."
            echo "Email associated with certificate being used for signing: '$BCM_PROJECT_CERTIFICATE_EMAIL'"
            echo "Git Commit Message: '$BCM_GIT_COMMIT_MESSAGE'"
            echo "Git Client Username: '$BCM_GIT_CLIENT_USERNAME'"

            docker exec -it -e BCM_PROJECT_CERTIFICATE_EMAIL="$BCM_PROJECT_CERTIFICATE_EMAIL" \
                -e BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME" \
                -e BCM_GIT_SIGNING_KEY="$BCM_GIT_SIGNING_KEY" \
                -e BCM_GIT_COMMIT_MESSAGE="$BCM_GIT_COMMIT_MESSAGE" \
                bcmtrezoragent /commit_sign_git_repo.sh

            docker kill bcmtrezoragent
            docker system prune -f
        fi
    fi
else
    echo "bad syntax."
fi



#gpg --output /gitrepo/$INPUT_FILE_NAME.decrypted --decrypt /gitrepo/$INPUT_FILE_NAME
# git config --local commit.gpgsign 1
# git config --local gpg.program $(which gpg2)
# git commit --gpg-sign                      # create GPG-signed commit
# git log --show-signature -1                # verify commit signature
# git tag v1.2.3 --sign                      # create GPG-signed tag
# git tag v1.2.3 --verify                    # verify tag signature
