#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE="${2:-}"
if [ ! -z "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a project command."
    cat ./help.txt
    exit
fi

GIT_REPO_DIR="$BCM_GIT_DIR"
#GIT_REPO_DIR="/home/ai/git/github/bcm_git_test"
GIT_COMMIT_MESSAGE=
GIT_CLIENT_USERNAME=
DEFAULT_KEY_ID=
BCM_GIT_TAG_NAME=
BCM_GIT_TAG_NOTE=

for i in "$@"; do
    case $i in
        --git-repo-dir=*)
            GIT_REPO_DIR="${i#*=}"
            shift # past argument=value
        ;;
        --message=*)
            GIT_COMMIT_MESSAGE="${i#*=}"
            shift # past argument=value
        ;;
        --annotate=*)
            BCM_GIT_TAG_NOTE="${i#*=}"
            shift # past argument=value
        ;;
        --tag=*)
            BCM_GIT_TAG_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

# if BCM_PROJECT_DIR is empty, we'll check to see if someone over-rode
# the trezor directory. If so, we'll send that in instead.
if [[ $BCM_HELP_FLAG == 1 ]]; then
    cat ./commit/help.txt
    exit
fi

if [[ ! -d $GNUPGHOME ]]; then
    echo "GNUPGHOME '$GNUPGHOME' doesn't exist."
    exit
fi

if [[ ! -d $GIT_REPO_DIR ]]; then
    echo "GIT_REPO_DIR '$GIT_REPO_DIR' doesn't exist."
    exit
fi

if [[ ! -f "$GNUPGHOME/env" ]]; then
    echo "ERROR: $GNUPGHOME/env does not exist.  Can't source."
    exit
fi

# shellcheck disable=SC1090
source "$GNUPGHOME/env"

if [[ -z $GIT_CLIENT_USERNAME ]]; then
    echo "Required parameter GIT_CLIENT_USERNAME not specified. The git repo config user.name will be used."
fi


if [[ -z $DEFAULT_KEY_ID ]]; then
    echo "Required parameter DEFAULT_KEY_ID not specified."
    exit
fi

export GIT_REPO_DIR="$GIT_REPO_DIR"
export GIT_CLIENT_USERNAME="$GIT_CLIENT_USERNAME"
export GIT_COMMIT_MESSAGE="$GIT_COMMIT_MESSAGE"
export DEFAULT_KEY_ID="$DEFAULT_KEY_ID"

# now call the appropritate script.
if [[ $BCM_CLI_VERB == "commit" ]]; then
    if [[ -z $GIT_COMMIT_MESSAGE ]]; then
        echo "Required parameter GIT_COMMIT_MESSAGE not specified. Use '--message='"
        exit
    fi
    
    if [[ $BCM_DEBUG == 1 ]]; then
        echo "GNUPGHOME: $GNUPGHOME"
        echo "GIT_COMMIT_MESSAGE: $GIT_COMMIT_MESSAGE"
        echo "GIT_REPO_DIR: $GIT_REPO_DIR"
        echo "GIT_CLIENT_USERNAME: $GIT_CLIENT_USERNAME"
        echo "DEFAULT_KEY_ID: $DEFAULT_KEY_ID"
    fi
    
    if ! docker ps | grep -q "gitter"; then
        # shellcheck disable=SC1090
        source "$BCM_GIT_DIR/controller/export_usb_path.sh"
        docker run -it --rm --name gitter \
        -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
        -v "$GNUPGHOME":/home/user/.gnupg \
        -v "$GIT_REPO_DIR":/gitrepo \
        --device="$BCM_TREZOR_USB_PATH" \
        -e GIT_CLIENT_USERNAME="$GIT_CLIENT_USERNAME" \
        -e BCM_EMAIL_ADDRESS="$BCM_CERT_USERNAME"'@'"$BCM_CERT_HOSTNAME" \
        -e GIT_COMMIT_MESSAGE="$GIT_COMMIT_MESSAGE" \
        -e DEFAULT_KEY_ID="$DEFAULT_KEY_ID" \
        "bcm-gpgagent:$BCM_VERSION" /bcm/commit_sign_git_repo.sh
    fi
    
    # if docker ps | grep -q "gitter"; then
    #     docker exec -it gitter
    # fi
fi

if [[ $BCM_CLI_VERB == "tag" ]]; then
    if [[ -z $BCM_GIT_TAG_NAME ]]; then
        echo "Required parameter BCM_GIT_TAG_NAME not specified. Use '--tag='"
        exit
    fi
    
    if [[ $BCM_DEBUG == 1 ]]; then
        echo "GNUPGHOME: $GNUPGHOME"
        echo "GIT_REPO_DIR: $GIT_REPO_DIR"
        echo "GIT_CLIENT_USERNAME: $GIT_CLIENT_USERNAME"
        echo "DEFAULT_KEY_ID: $DEFAULT_KEY_ID"
        echo "BCM_GIT_TAG_NAME: $BCM_GIT_TAG_NAME"
        echo "BCM_GIT_TAG_NOTE: $BCM_GIT_TAG_NOTE"
    fi
    
    if ! docker ps | grep -q "gitter"; then
        # shellcheck disable=SC1090
        source "$BCM_GIT_DIR/controller/export_usb_path.sh"
        docker run -it --rm --name gitter \
        -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
        -v "$GNUPGHOME":/home/user/.gnupg \
        -v "$GIT_REPO_DIR":/gitrepo \
        --device="$BCM_TREZOR_USB_PATH" \
        -e GIT_CLIENT_USERNAME="$GIT_CLIENT_USERNAME" \
        -e BCM_EMAIL_ADDRESS="$BCM_CERT_USERNAME"'@'"$BCM_CERT_HOSTNAME" \
        -e BCM_GIT_TAG_NAME="$BCM_GIT_TAG_NAME" \
        -e BCM_GIT_TAG_NOTE="$BCM_GIT_TAG_NOTE" \
        -e DEFAULT_KEY_ID="$DEFAULT_KEY_ID" \
        "bcm-gpgagent:$BCM_VERSION" /bcm/commit_sign_git_repo.sh
    fi
    
    # if docker ps | grep -q "gitter"; then
    #     docker exec -it gitter
    # fi
fi

if docker ps | grep -q "gitter"; then
    docker kill gitter >/dev/null
    docker system prune -f >/dev/null
fi