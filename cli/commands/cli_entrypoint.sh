#!/bin/bash

set -e
cd "$(dirname "$0")"

export BCM_CLI_COMMAND=$1
export BCM_CLI_VERB=$2

shopt -s expand_aliases

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
    --force)
    BCM_FORCE_FLAG=1
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

if [[ $BCM_DEBUG = 1 ]]; then
    cat "BCM_CERTS_DIR: $BCM_CERTS_DIR" >>$BCM_CERTS_DEBUG_FILE
    cat "BCM_PROJECTS_DIR: $BCM_PROJECTS_DIR" >>$BCM_CERTS_DEBUG_FILE
    cat "BCM_CLUSTERS_DIR: $BCM_CLUSTERS_DIR" >>$BCM_CERTS_DEBUG_FILE
    cat "BCM_PASSWORDS_DIR: $BCM_PASSWORDS_DIR" >>$BCM_CERTS_DEBUG_FILE
fi

# make sure docker is isstalled. Doing it here makes sure we don't have to
# do it anywhere else.
$BCM_LOCAL_GIT_REPO_DIR/cli/commands/install/snap_install_docker-ce.sh

if [[ $BCM_DEBUG = "true" ]]; then
    echo "BCM_CLI_COMMAND: $BCM_CLI_COMMAND"
fi

export BCM_HELP_FLAG=$BCM_HELP_FLAG
export BCM_FORCE_FLAG=$BCM_FORCE_FLAG
export BCM_DEBUG=$BCM_DEBUG

if [[ $BCM_CLI_COMMAND = "init" ]]; then 
    ./init.sh "$@"
elif [[ $BCM_CLI_COMMAND = "project" ]]; then
    ./project/entrypoint.sh "$@"
elif [[ $BCM_CLI_COMMAND = "cluster" ]]; then
    ./cluster/entrypoint.sh "$@"
elif [[ $BCM_CLI_COMMAND = "git" ]]; then
    ./git/entrypoint.sh "$@"
elif [[ $BCM_CLI_COMMAND = "file" ]]; then
    ./file/entrypoint.sh "$@"
elif [[ $BCM_CLI_COMMAND = "ssh" ]]; then
    ./ssh/entrypoint.sh "$@"
elif [[ $BCM_CLI_COMMAND = "info" ]]; then
    bash -c './info.sh "$@"'
elif [[ $BCM_CLI_COMMAND = "show" ]]; then
    $BCM_LOCAL_GIT_REPO_DIR/lxd/show_lxd.sh
else
    cat ./help.txt
fi