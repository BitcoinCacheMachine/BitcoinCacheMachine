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

BCM_HELP_FLAG=0
BCM_GIT_REPO_DIR=
BCM_GIT_COMMIT_MESSAGE=
BCM_GIT_CLIENT_USERNAME=
BCM_GPG_SIGNING_KEY_ID=

for i in "$@"; do
    case $i in
        --dir*)
            GNUPGHOME="${i#*=}"
            shift # past argument=value
        ;;
        --git-repo-dir=*)
            BCM_GIT_REPO_DIR="${i#*=}"
            shift # past argument=value
        ;;
        --git-commit-message=*)
            BCM_GIT_COMMIT_MESSAGE="${i#*=}"
            shift # past argument=value
        ;;
        --git-username=*)
            BCM_GIT_CLIENT_USERNAME="${i#*=}"
            shift # past argument=value
        ;;
        --email-address=*)
            BCM_EMAIL_ADDRESS="${i#*=}"
            shift # past argument=value
        ;;
        --gpg-signing-key-id=*)
            BCM_GPG_SIGNING_KEY_ID="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ ! -d $GNUPGHOME ]]; then
    echo "GNUPGHOME '$GNUPGHOME' doesn't exist."
    exit
fi

if [[ ! -d $BCM_GIT_REPO_DIR ]]; then
    echo "BCM_GIT_REPO_DIR '$BCM_GIT_REPO_DIR' doesn't exist."
    exit
fi

if [[ -z $BCM_GIT_CLIENT_USERNAME ]]; then
    echo "Required parameter BCM_GIT_CLIENT_USERNAME not specified. The git repo config user.name will be used."
fi


if [[ -z $BCM_GIT_COMMIT_MESSAGE ]]; then
    echo "Required parameter BCM_GIT_COMMIT_MESSAGE not specified."
    exit
fi


if [[ -z $BCM_EMAIL_ADDRESS ]]; then
    echo "Required parameter BCM_EMAIL_ADDRESS not specified."
    exit
fi

if [[ -z $BCM_GPG_SIGNING_KEY_ID ]]; then
    echo "Required parameter BCM_GPG_SIGNING_KEY_ID not specified."
    exit
fi

export BCM_GIT_REPO_DIR=$BCM_GIT_REPO_DIR
export BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME"
export BCM_GIT_COMMIT_MESSAGE="$BCM_GIT_COMMIT_MESSAGE"
export BCM_EMAIL_ADDRESS="$BCM_EMAIL_ADDRESS"
export BCM_GPG_SIGNING_KEY_ID=$BCM_GPG_SIGNING_KEY_ID

# now call the appropritae script.
if [[ $BCM_CLI_VERB == "commit" ]]; then
    # if BCM_PROJECT_DIR is empty, we'll check to see if someone over-rode
    # the trezor directory. If so, we'll send that in instead.
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./commands/git/commit/help.txt
        exit
    fi
    
    if [[ $BCM_DEBUG == 1 ]]; then
        echo "GNUPGHOME: $GNUPGHOME"
        echo "BCM_GIT_COMMIT_MESSAGE: $BCM_GIT_COMMIT_MESSAGE"
        echo "BCM_GIT_REPO_DIR: $BCM_GIT_REPO_DIR"
        echo "BCM_GIT_CLIENT_USERNAME: $BCM_GIT_CLIENT_USERNAME"
        echo "BCM_EMAIL_ADDRESS: $BCM_EMAIL_ADDRESS"
        echo "BCM_GPG_SIGNING_KEY_ID: $BCM_GPG_SIGNING_KEY_ID"
    fi
    
    if ! sudo docker ps | grep -q "gitter"; then
        # shellcheck disable=SC1090
        source "$BCM_GIT_DIR/controller/export_usb_path.sh"
        sudo docker run -d --name gitter \
        -v "$GNUPGHOME":/root/.gnupg \
        -v $BCM_GIT_REPO_DIR:/gitrepo \
        --device="$BCM_TREZOR_USB_PATH" \
        -e BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME" \
        -e BCM_EMAIL_ADDRESS="$BCM_EMAIL_ADDRESS" \
        -e BCM_GIT_COMMIT_MESSAGE="$BCM_GIT_COMMIT_MESSAGE" \
        -e BCM_GPG_SIGNING_KEY_ID="$BCM_GPG_SIGNING_KEY_ID" \
        bcm-gpgagent:latest
        
        sleep 2
    fi
    
    if sudo docker ps | grep -q "gitter"; then
        sudo docker exec -it gitter /bcm/commit_sign_git_repo.sh
    fi
    
    elif [[ $BCM_CLI_VERB == "push" ]]; then
    echo "git push TODO"
else
    cat ./git/help.txt
fi

if sudo docker ps | grep -q "gitter"; then
    sudo docker kill gitter >/dev/null
    sudo docker system prune -f >/dev/null
else
    echo "Error. Docker container 'gitter' was not running."
fi