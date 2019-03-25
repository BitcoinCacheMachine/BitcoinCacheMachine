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
GIT_REPO_DIR="$GNUPGHOME"
BCM_GIT_COMMIT_MESSAGE=
BCM_GIT_CLIENT_USERNAME=
BCM_DEFAULT_KEY_ID=
SSH_HOSTNAME=
SSH_USERNAME=

for i in "$@"; do
    case $i in
        --dir*)
            GNUPGHOME="${i#*=}"
            shift # past argument=value
        ;;
        --git-repo-dir=*)
            GIT_REPO_DIR="${i#*=}"
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
        --key-id=*)
            BCM_DEFAULT_KEY_ID="${i#*=}"
            shift # past argument=value
        ;;
        --hostname=*)
            SSH_HOSTNAME="${i#*=}"
            shift # past argument=value
        ;;
        --username=*)
            SSH_USERNAME="${i#*=}"
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

if [[ -z $BCM_GIT_CLIENT_USERNAME ]]; then
    echo "Required parameter BCM_GIT_CLIENT_USERNAME not specified. The git repo config user.name will be used."
fi


if [[ -z $BCM_DEFAULT_KEY_ID ]]; then
    echo "Required parameter BCM_DEFAULT_KEY_ID not specified."
    exit
fi

export GIT_REPO_DIR="$GIT_REPO_DIR"
export BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME"
export BCM_GIT_COMMIT_MESSAGE="$BCM_GIT_COMMIT_MESSAGE"
export BCM_DEFAULT_KEY_ID="$BCM_DEFAULT_KEY_ID"

# now call the appropritae script.
if [[ $BCM_CLI_VERB == "commit" ]]; then
    if [[ -z $BCM_GIT_COMMIT_MESSAGE ]]; then
        echo "Required parameter BCM_GIT_COMMIT_MESSAGE not specified."
        exit
    fi
    
    # if BCM_PROJECT_DIR is empty, we'll check to see if someone over-rode
    # the trezor directory. If so, we'll send that in instead.
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./commands/git/commit/help.txt
        exit
    fi
    
    if [[ $BCM_DEBUG == 1 ]]; then
        echo "GNUPGHOME: $GNUPGHOME"
        echo "BCM_GIT_COMMIT_MESSAGE: $BCM_GIT_COMMIT_MESSAGE"
        echo "GIT_REPO_DIR: $GIT_REPO_DIR"
        echo "BCM_GIT_CLIENT_USERNAME: $BCM_GIT_CLIENT_USERNAME"
        echo "BCM_DEFAULT_KEY_ID: $BCM_DEFAULT_KEY_ID"
    fi
    
    if ! docker ps | grep -q "gitter"; then
        # shellcheck disable=SC1090
        source "$BCM_GIT_DIR/controller/export_usb_path.sh"
        docker run -d --name gitter \
        -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
        -v "$GNUPGHOME":/home/user/.gnupg \
        -v "$GIT_REPO_DIR":/gitrepo \
        --device="$BCM_TREZOR_USB_PATH" \
        -e BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME" \
        -e BCM_EMAIL_ADDRESS="$BCM_CERT_USERNAME"'@'"$BCM_CERT_HOSTNAME" \
        -e BCM_GIT_COMMIT_MESSAGE="$BCM_GIT_COMMIT_MESSAGE" \
        -e BCM_DEFAULT_KEY_ID="$BCM_DEFAULT_KEY_ID" \
        bcm-gpgagent:latest
        
        sleep 2
    fi
    
    if docker ps | grep -q "gitter"; then
        docker exec -it gitter /bcm/commit_sign_git_repo.sh
    fi
fi


if [[ $BCM_CLI_VERB == "push" ]]; then
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./push/help.txt
        exit
    fi
    
    # shellcheck disable=SC1090
    source "$BCM_GIT_DIR/controller/export_usb_path.sh"
    
    IP_ADDRESS=$(dig +short "$SSH_HOSTNAME" | head -n 1)
    docker run -it --rm --add-host="$SSH_HOSTNAME:$IP_ADDRESS" \
    -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
    -v "$BCM_SSH_DIR":/home/user/.ssh \
    -v "$GIT_REPO_DIR":/gitrepo \
    -e BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME" \
    -e SSH_USERNAME="$SSH_USERNAME" \
    -e SSH_HOSTNAME="$SSH_HOSTNAME" \
    --device="$BCM_TREZOR_USB_PATH" \
    bcm-trezor:latest trezor-agent $SSH_USERNAME@$SSH_HOSTNAME -- service tor start && wait-for-it -t 10 127.0.0.1:9050 && git config --local http.proxy socks5://127.0.0.1:9050 && git config --local user.name "$BCM_GIT_CLIENT_USERNAME" && git push
fi

if docker ps | grep -q "gitter"; then
    docker kill gitter >/dev/null
    docker system prune -f >/dev/null
fi