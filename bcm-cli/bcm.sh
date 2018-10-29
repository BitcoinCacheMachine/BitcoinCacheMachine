#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

export BCM_CLI_COMMAND=$1
export BCM_CLI_VERB=$2
export BCM_CLI_OBJECT=$3

shopt -s expand_aliases
source ~/.bashrc

BCM_PROJECT_NAME=
BCM_PROJECT_USERNAME=
BCM_PROJECT_CLUSTERNAME=
BCM_PROJECT_DIR=
BCM_PROJECT_OVERRIDE_DIR=
export BCM_FORCE_FLAG=0
export BCM_DEBUG=false

for i in "$@"
do
case $i in
    -n=*|--bcm-project-name=*)
    BCM_PROJECT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    -u=*|--user-name=*)
    BCM_PROJECT_USERNAME="${i#*=}"
    shift # past argument=value
    ;;
    -c=*|--cluster-name=*)
    BCM_PROJECT_CLUSTERNAME="${i#*=}"
    shift # past argument=value
    ;;
    -m=*|--git-commit-message=*)
    BCM_GIT_COMMIT_MESSAGE="${i#*=}"
    shift # past argument=value
    ;;
    -g=*|--git-repo-dir=*)
    BCM_GIT_REPO_DIR="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--file-path=*)
    BCM_TREZOR_FILE_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -i=*|--git-client-username=*)
    BCM_GIT_CLIENT_USERNAME="${i#*=}"
    shift # past argument=value
    ;;
    -e=*|--email-address=*)
    BCM_EMAIL_ADDRESS="${i#*=}"
    shift # past argument=value
    ;;
    -o=*|--project-override=*)
    BCM_PROJECT_OVERRIDE_DIR="${i#*=}"
    shift # past argument=value
    ;;
    --help)
    BCM_HELP_FLAG=1
    shift # past argument=value
    ;;
    -f|--force)
    BCM_FORCE_FLAG=1
    shift # past argument=value
    ;;
    -d|--directory)
    BCM_DIRECTORY_FLAG=1
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

function checkTrezor {
    BCM_TREZOR_USB_PATH=
    source $BCM_LOCAL_GIT_REPO/trezor/export_usb_path.sh
    if [[ -z $BCM_TREZOR_USB_PATH ]]; then
        exit
    fi
}

if [[ $BCM_DEBUG = "true" ]]; then
    echo "BCM_CLI_COMMAND: $BCM_CLI_COMMAND"
    echo "BCM_CLI_VERB: $BCM_CLI_VERB"
fi

if [[ $BCM_CLI_COMMAND = "project" ]]; then
    # call the appropriate sciprt.
    if [[ $BCM_CLI_VERB = "create" ]]; then
 
        source $BCM_LOCAL_GIT_REPO/resources/export_bcm_envs.sh

        if [[ -z $BCM_CLI_OBJECT ]]; then
            printf "\n" && echo "$(cat ./project/create/help.txt)"
            exit
        fi

        export BCM_PROJECT_NAME=$BCM_CLI_OBJECT
        export BCM_PROJECT_USERNAME=$BCM_PROJECT_USERNAME
        export BCM_PROJECT_CLUSTERNAME=$BCM_PROJECT_CLUSTERNAME
        checkTrezor
        bash -c ./commands/project/create/create.sh
    elif [[ $BCM_CLI_VERB = "destroy" ]]; then
        export BCM_PROJECT_NAME=$BCM_CLI_OBJECT
        env BCM_FORCE_FLAG=$BCM_FORCE_FLAG bash -c ./commands/project/destroy/destroy.sh
    elif [[ $BCM_CLI_VERB = "get-default" ]]; then
        export BCM_DIRECTORY_FLAG=$BCM_DIRECTORY_FLAG
        bash -c ./commands/project/getdefault/getdefault.sh
    elif [[ $BCM_CLI_VERB = "set-default" ]]; then
        export BCM_NEW_PROJECT_NAME=$BCM_CLI_OBJECT
        bash -c ./commands/project/setdefault/setdefault.sh
    elif [[ $BCM_CLI_VERB = "list" ]]; then
        bash -c ./commands/project/list/list.sh
    else
        echo "Error: '$BCM_CLI_VERB' is not a valid command."
        printf "\n" && echo "$(cat ./commands/project/help.txt)"
    fi
elif [[ $BCM_CLI_COMMAND = "cluster" ]]; then
    if [[ $BCM_CLI_VERB = "create" ]]; then
        echo "cluster create"
    elif [[ $BCM_CLI_VERB = "destroy" ]]; then
        echo "cluster destroy"
    fi
elif [[ $BCM_CLI_COMMAND = "git" ]]; then
    if [[ $BCM_CLI_VERB = "commit" ]]; then
        # if BCM_PROJECT_DIR is empty, we'll check to see if someone over-rode
        # the trezor directory. If so, we'll send that in instead.
        if [[ $BCM_HELP_FLAG = 1 ]]; then
            printf "\n" && echo "$(cat ./commands/git/commit/help.txt)"
        fi

        if [[ -z $BCM_GIT_REPO_DIR ]]; then
            echo "Required parameter BCM_GIT_REPO_DIR not specified."
            exit
        else
            if [[ -d "$BCM_GIT_REPO_DIR" ]]; then
                export BCM_GIT_REPO_DIR=$BCM_GIT_REPO_DIR
            else
                echo "BCM_GIT_REPO_DIR does not appear to exist."
                exit
            fi
        fi

        if [[ -z $BCM_GIT_COMMIT_MESSAGE ]]; then
            echo "Required parameter BCM_GIT_COMMIT_MESSAGE not specified."
            exit
        fi

        if [[ -z $BCM_GIT_CLIENT_USERNAME ]]; then
            echo "Required parameter BCM_GIT_CLIENT_USERNAME not specified."
            exit
        fi

        if [[ ! -z $BCM_PROJECT_OVERRIDE_DIR ]]; then
            if [[ -d $BCM_PROJECT_OVERRIDE_DIR ]]; then
                export BCM_PROJECT_DIR=$BCM_PROJECT_OVERRIDE_DIR
            fi
        else
            ACTIVE_BCM_PROJECT_DIR=$($BCM_LOCAL_GIT_REPO/bcm-cli/bcm.sh project get-default -d)
            if [[ ! -d $ACTIVE_BCM_PROJECT_DIR ]]; then
                echo "The public key material directory could not be determined. Please set BCM_PROJECT_OVERRIDE_DIR."
                printf "\n" && echo "$(cat ./commands/git/commit/help.txt)"
                exit
            else
                # we'll set the BCM_PROJECT_DIR to the active DIR
                export BCM_PROJECT_DIR=$ACTIVE_BCM_PROJECT_DIR
            fi
        fi

        if [[ -z $BCM_EMAIL_ADDRESS ]]; then
            echo "Required parameter BCM_EMAIL_ADDRESS not specified."
            exit
        else
            EMAIL_REGEX="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

            if [[ $BCM_EMAIL_ADDRESS =~ $EMAIL_REGEX ]] ; then
                export BCM_EMAIL_ADDRESS=$BCM_EMAIL_ADDRESS
            else
                echo "BCM_EMAIL_ADDRESS is not a valid email address."
            fi
        fi
        
        checkTrezor
        export BCM_GIT_COMMIT_MESSAGE=$BCM_GIT_COMMIT_MESSAGE
        export BCM_GIT_CLIENT_USERNAME=$BCM_GIT_CLIENT_USERNAME
        export BCM_TREZOR_USB_PATH=$BCM_TREZOR_USB_PATH

        echo "BCM_PROJECT_DIR: $BCM_PROJECT_DIR"
        echo "BCM_GIT_COMMIT_MESSAGE: $BCM_GIT_COMMIT_MESSAGE"
        echo "BCM_GIT_REPO_DIR: $BCM_GIT_REPO_DIR"
        echo "BCM_GIT_CLIENT_USERNAME: $BCM_GIT_CLIENT_USERNAME"
        echo "BCM_EMAIL_ADDRESS: $BCM_EMAIL_ADDRESS"
        echo "BCM_TREZOR_USB_PATH: $BCM_TREZOR_USB_PATH"

        bash -c ./commands/git/commit/commitsign.sh
    else
        printf "\n" && echo "$(cat ./commands/git/help.txt)"
    fi

elif [[ $BCM_CLI_COMMAND = "file" ]]; then
    if [[ $BCM_CLI_VERB = "encrypt" ]]; then
        if [[ ! -f $BCM_CLI_OBJECT ]]; then
            echo "Error: BCM_TREZOR_FILE_PATH not specified."
            printf "\n" && echo "$(cat ./commands/file/encrypt/help.txt)"
            exit
        fi

        checkTrezor

        export BCM_TREZOR_FILE_PATH=$BCM_TREZOR_FILE_PATH

        if [[ ! -z $($BCM_LOCAL_GIT_REPO/bcm-cli/bcm.sh project get-default | grep "No active project set.") ]]; then
            
            
            export BCM_PROJECT_DIR=$BCM_PROJECT_DIR
        fi

        export BCM_PROJECT_NAME=$($BCM_LOCAL_GIT_REPO/bcm-cli/bcm.sh project get-default)
        
        bash -c "./commands/file/encrypt/encrypt.sh"
    fi
else
    cat ./help.txt
fi