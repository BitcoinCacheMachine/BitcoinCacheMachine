#!/bin/bash


set -eu
cd "$(dirname "$0")"

BCM_CLI_VERB=$2
BCM_HELP_FLAG=0
BCM_GIT_REPO_DIR="$BCM_RUNTIME_DIR"
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
    echo "BCM_CERT_DIR does not exist. Exiting."
    exit
fi
export BCM_CERT_DIR=$BCM_CERT_DIR


if [[ ! -d $BCM_GIT_REPO_DIR ]]; then
    echo "Directory $BCM_GIT_REPO_DIR doesn't exist."
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
    ./commit/commitsign.sh "$@"
elif [[ $BCM_CLI_VERB = "push" ]]; then
    echo "git push TODO"
else
    cat ./git/help.txt
fi
