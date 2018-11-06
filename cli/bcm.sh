#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

export BCM_CLI_COMMAND=$1
export BCM_CLI_VERB=$2


shopt -s expand_aliases
source $HOME/.bashrc

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
$BCM_LOCAL_GIT_REPO_DIR/cli/commands/shared/snap_install_docker-ce.sh

if [[ $BCM_DEBUG = "true" ]]; then
    echo "BCM_CLI_COMMAND: $BCM_CLI_COMMAND"
fi

export BCM_DEBUG=$BCM_DEBUG
export BCM_HELP_FLAG=$BCM_HELP_FLAG

if [[ $BCM_CLI_COMMAND = "init" ]]; then 
    ./commands/init.sh "$@"
elif [[ $BCM_CLI_COMMAND = "project" ]]; then
    ./commands/project/entrypoint.sh "$@"
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