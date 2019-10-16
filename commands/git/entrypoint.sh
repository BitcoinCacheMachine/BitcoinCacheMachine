#!/bin/bash

set -Eeuox pipefail
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
cd "$GIT_REPO_DIR" || exit
GIT_COMMIT_MESSAGE=
BCM_GIT_TAG_NAME=
BCM_GIT_BRANCH=
BCM_GIT_PUSH=0
STAGE_OUTSTANDING=0

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
        --tag=*)
            BCM_GIT_TAG_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --stage)
            STAGE_OUTSTANDING=1
            shift # past argument=value
        ;;
        --branch-name=*)
            BCM_GIT_BRANCH="${i#*=}"
            shift # past argument=value
        ;;
        --push)
            BCM_GIT_PUSH=1
            shift # past argument=value
        ;;
        *)
    esac
done

GIT_DOCKER_IMAGE="bcm-gpgagent:$BCM_VERSION"
if [[ ! -d "$GIT_REPO_DIR/.git" ]]; then
    echo "GIT_REPO_DIR '$GIT_REPO_DIR' doesn't exist."
    exit
fi

if [[ "$#" -le 2 ]]; then
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./help.txt
        exit
    fi
fi

# now call the appropritate script.
if [[ $BCM_CLI_VERB == "commit" ]]; then
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./commit/help.txt
        exit
    fi
    
    if [[ -z $GIT_COMMIT_MESSAGE ]]; then
        echo "Required parameter GIT_COMMIT_MESSAGE not specified. Use '--message='"
        exit
    fi
    
    if ! docker ps | grep -q "gitter"; then
        # shellcheck disable=SC1090
        source "$BCM_GIT_DIR/controller/export_usb_path.sh"
        
        if [[ $STAGE_OUTSTANDING == 1 ]]; then
            cd "$GIT_REPO_DIR" && git add * && cd -
        fi
        
        docker run -it --rm --name gitter \
        -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
        -v "$GNUPGHOME":/home/user/.gnupg \
        -v "$GIT_REPO_DIR":/home/user/gitrepo \
        --device="$BCM_TREZOR_USB_PATH" \
        -e GIT_COMMIT_MESSAGE="$GIT_COMMIT_MESSAGE" \
        -e DEFAULT_KEY_ID="$DEFAULT_KEY_ID" \
        "$GIT_DOCKER_IMAGE" /home/user/bcmscripts/commit_sign_git_repo.sh
    fi
    
    # if the user set the push flag, then let's run git push
    if [ $BCM_GIT_PUSH == 1 ]; then
        cd "$GIT_REPO_DIR" && git push && cd --
    fi
fi

if [[ $BCM_CLI_VERB == "tag" ]]; then
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./tag/help.txt
        exit
    fi
    
    if [[ -z $BCM_GIT_TAG_NAME ]]; then
        echo "Required parameter BCM_GIT_TAG_NAME not specified. Use '--tag='"
        exit
    fi
    
    if [[ -z $GIT_COMMIT_MESSAGE ]]; then
        echo "Required parameter GIT_COMMIT_MESSAGE not specified. Use '--message='"
        exit
    fi
    
    if ! docker ps | grep -q "gitter"; then
        # shellcheck disable=SC1090
        source "$BCM_GIT_DIR/controller/export_usb_path.sh"
        docker run -it --rm --name gitter \
        -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
        -v "$GNUPGHOME":/home/user/.gnupg \
        -v "$GIT_REPO_DIR":/home/user/gitrepo \
        --device="$BCM_TREZOR_USB_PATH" \
        -e BCM_GIT_TAG_NAME="$BCM_GIT_TAG_NAME" \
        -e GIT_COMMIT_MESSAGE="$GIT_COMMIT_MESSAGE" \
        -e DEFAULT_KEY_ID="$DEFAULT_KEY_ID" \
        "$GIT_DOCKER_IMAGE" /home/user/bcmscripts/tag_sign_git_repo.sh
    fi
fi

if [[ $BCM_CLI_VERB == "merge" ]]; then
    if [[ $BCM_HELP_FLAG == 1 ]]; then
        cat ./merge/help.txt
        exit
    fi
    
    if [[ -z $BCM_GIT_BRANCH ]]; then
        echo "Required parameter BCM_GIT_BRANCH not specified. Use '--branch-name=<branch>'"
        exit
    fi
    
    if ! docker ps | grep -q "gitter"; then
        # shellcheck disable=SC1090
        source "$BCM_GIT_DIR/controller/export_usb_path.sh"
        docker run -it --rm --name gitter \
        -v "$BCM_TREZOR_USB_PATH":"$BCM_TREZOR_USB_PATH" \
        -v "$GNUPGHOME":/home/user/.gnupg \
        -v "$GIT_REPO_DIR":/home/user/gitrepo \
        --device="$BCM_TREZOR_USB_PATH" \
        -e BCM_GIT_BRANCH="$BCM_GIT_BRANCH" \
        -e DEFAULT_KEY_ID="$DEFAULT_KEY_ID" \
        "$GIT_DOCKER_IMAGE" /home/user/bcmscripts/merge_sign_git_repo.sh
    fi
fi

if docker ps | grep -q "gitter"; then
    docker kill gitter >/dev/null
    docker system prune -f >/dev/null
fi
