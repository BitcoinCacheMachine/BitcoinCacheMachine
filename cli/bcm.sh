#!/bin/bash

set -eu

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

export BCM_CLI_COMMAND=$1

shopt -s expand_aliases
source ~/.bashrc

BCM_PROJECT_NAME=
BCM_PROJECT_USERNAME=
BCM_CLUSTER_NAME=
BCM_PROJECT_DIR=
BCM_CERT_DIR_OVERRIDE=
BCM_GIT_REPO_DIR=
BCM_MGMT_TYPE=
BCM_PROVIDER_NAME=
BCM_CLUSTER_NODE_COUNT=1
BCM_HELP_FLAG=0
BCM_FORCE_FLAG=0
BCM_DEBUG=0

for i in "$@"
do
case $i in
    --help)
    BCM_HELP_FLAG=1
    shift # past argument=value
    ;;
    --debug)
    BCM_DEBUG=1
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

# make sure docker is isstalled. Doing it here makes sure we don't have to
# do it anywhere else.
$BCM_LOCAL_GIT_REPO/cli/commands/shared/snap_install_docker-ce.sh

if [[ $BCM_DEBUG = "true" ]]; then
    echo "BCM_CLI_COMMAND: $BCM_CLI_COMMAND"
    echo "BCM_CLI_VERB: $BCM_CLI_VERB"
fi

export BCM_HELP_FLAG=$BCM_HELP_FLAG

if [[ $BCM_CLI_COMMAND = "init" ]]; then 
    ./commands/init.sh "$@"
elif [[ $BCM_CLI_COMMAND = "project" ]]; then
    # call the appropriate sciprt.
    if [[ $BCM_CLI_VERB = "create" ]]; then
 
        source $BCM_LOCAL_GIT_REPO/resources/export_bcm_envs.sh

        if [[ -z $BCM_CLI_OBJECT ]]; then
            printf "\n" && echo "$(cat ./project/create/help.txt)"
            exit
        fi

        export BCM_PROJECT_NAME=$BCM_CLI_OBJECT
        export BCM_PROJECT_USERNAME=$BCM_PROJECT_USERNAME
        export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
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
        cat ./commands/project/help.txt
    fi
elif [[ $BCM_CLI_COMMAND = "cluster" ]]; then
    ./commands/cluster/entrypoint.sh "$@"
elif [[ $BCM_CLI_COMMAND = "git" ]]; then
    ./commands/git/entrypoint.sh "$@"
elif [[ $BCM_CLI_COMMAND = "file" ]]; then
    ./commands/file/entrypoint.sh "$@"
elif [[ $BCM_CLI_COMMAND = "info" ]]; then
    bash -c './commands/info.sh "$@"'
else
    cat ./help.txt
fi