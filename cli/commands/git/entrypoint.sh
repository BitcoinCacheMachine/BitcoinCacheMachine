#!/bin/bash


set -eu
cd "$(dirname "$0")"
echo "git entrypoint.sh"


BCM_CLI_VERB=$2
BCM_HELP_FLAG=0
BCM_GIT_REPO_DIR=
BCM_CERT_DIR="$BCM_RUNTIME_DIR/certs"
BCM_GIT_COMMIT_MESSAGE=
BCM_GIT_CLIENT_USERNAME=
BCM_GPG_SIGNING_KEY_ID=

for i in "$@"
do
case $i in
    --cert-dir=*)
    BCM_CERT_DIR="${i#*=}"
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

if [[ ! -d $BCM_CERT_DIR ]]; then
    echo "BCM_CERT_DIR '$BCM_CERT_DIR' doesn't exist."
    exit
fi
export BCM_CERT_DIR=$BCM_CERT_DIR


if [[ ! -d $BCM_GIT_REPO_DIR ]]; then
    echo "BCM_GIT_REPO_DIR '$BCM_GIT_REPO_DIR' doesn't exist."
    exit
fi
export BCM_GIT_REPO_DIR=$BCM_GIT_REPO_DIR


if [[ -z $BCM_GIT_CLIENT_USERNAME ]]; then
    echo "Required parameter BCM_GIT_CLIENT_USERNAME not specified. The git repo config user.name will be used."
else
    export BCM_GIT_CLIENT_USERNAME=$BCM_GIT_CLIENT_USERNAME
fi

if [[ -z $BCM_GIT_COMMIT_MESSAGE ]]; then
    echo "Required parameter BCM_GIT_COMMIT_MESSAGE not specified."
    exit
fi
export BCM_GIT_COMMIT_MESSAGE=$BCM_GIT_COMMIT_MESSAGE


if [[ -z $BCM_EMAIL_ADDRESS ]]; then
    echo "Required parameter BCM_EMAIL_ADDRESS not specified."
    exit
fi
export BCM_EMAIL_ADDRESS=$BCM_EMAIL_ADDRESS

if [[ -z $BCM_GPG_SIGNING_KEY_ID ]]; then
    echo "Required parameter BCM_GPG_SIGNING_KEY_ID not specified."
    exit
fi
export BCM_GPG_SIGNING_KEY_ID=$BCM_GPG_SIGNING_KEY_ID

# now call the appropritae script.
if [[ $BCM_CLI_VERB = "commit" ]]; then
    # if BCM_PROJECT_DIR is empty, we'll check to see if someone over-rode
    # the trezor directory. If so, we'll send that in instead.
    if [[ $BCM_HELP_FLAG = 1 ]]; then
        cat ./commands/git/commit/help.txt
        exit
    fi
    
    # we need to stop any existing containers if there is any.
    if [[ $(docker ps | grep "gitter") ]]; then
        docker kill gitter
        sleep 2
    fi

    # we need to stop any existing containers if there is any.
    if [[ $(docker ps -a | grep "gitter") ]]; then
        docker system prune -f
        sleep 3
    fi

    bash -c "$BCM_LOCAL_GIT_REPO_DIR/mgmt_plane/build.sh"
    if [[ ! -z $(docker image list | grep "bcm-gpgagent:latest") ]]; then
        docker build -t bcm-gpgagent:latest .
    else
        # make sure the container is up-to-date, but don't display
        docker build -t bcm-gpgagent:latest . >> /dev/null
    fi


    if [[ $BCM_DEBUG = 1 ]]; then
        echo "BCM_CERT_DIR: $BCM_CERT_DIR"
        echo "BCM_GIT_COMMIT_MESSAGE: $BCM_GIT_COMMIT_MESSAGE"
        echo "BCM_GIT_REPO_DIR: $BCM_GIT_REPO_DIR"
        echo "BCM_GIT_CLIENT_USERNAME: $BCM_GIT_CLIENT_USERNAME"
        echo "BCM_EMAIL_ADDRESS: $BCM_EMAIL_ADDRESS"
        echo "BCM_GPG_SIGNING_KEY_ID: $BCM_GPG_SIGNING_KEY_ID"
    fi
    # get the locatio of the trezor
    export BCM_TREZOR_USB_PATH=$(bcm info | grep "TREZOR_USB_PATH" | awk 'NF>1{print $NF}')
    docker run -d --name gitter \
        -v $BCM_CERT_DIR:/root/.gnupg \
        -v $BCM_GIT_REPO_DIR:/gitrepo \
        --device="$BCM_TREZOR_USB_PATH" \
        -e BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME" \
        -e BCM_EMAIL_ADDRESS="$BCM_EMAIL_ADDRESS" \
        -e BCM_GIT_COMMIT_MESSAGE="$BCM_GIT_COMMIT_MESSAGE" \
        -e BCM_GPG_SIGNING_KEY_ID="$BCM_GPG_SIGNING_KEY_ID" \
        bcm-gpgagent:latest
    sleep 1
    docker exec -it gitter  /bcm/commit_sign_git_repo.sh

elif [[ $BCM_CLI_VERB = "push" ]]; then
    echo "git push TODO"
else
    cat ./git/help.txt
fi
