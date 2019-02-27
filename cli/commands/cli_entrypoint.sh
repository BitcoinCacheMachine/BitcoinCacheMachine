#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CLI_COMMAND=

if [[ ! -z ${1+x} ]]; then
    BCM_CLI_COMMAND="$1"
else
    cat ./help.txt
    exit
fi

export BCM_CLI_COMMAND="$BCM_CLI_COMMAND"

shopt -s expand_aliases

BCM_HELP_FLAG=0
BCM_FORCE_FLAG=0

for i in "$@"; do
    case $i in
        --help)
            BCM_HELP_FLAG=1
            shift # past argument=value
        ;;
        --force)
            BCM_FORCE_FLAG=1
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

export BCM_HELP_FLAG="$BCM_HELP_FLAG"
export BCM_FORCE_FLAG="$BCM_FORCE_FLAG"

if [[ "$BCM_CLI_COMMAND" == "reset" ]]; then
    ./reset.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "init" ]]; then
    ./init.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "pass" ]]; then
    ./pass/entrypoint.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "git" ]]; then
    ./git/entrypoint.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "file" ]]; then
    ./file/entrypoint.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "info" ]]; then
    ./info.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "cluster" ]]; then
    ./cluster/entrypoint.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "ssh" ]]; then
    ./ssh/entrypoint.sh "$@"
    exit
fi

# all the command below REQUIRE a HTTPS LXD endpoint. Stop here if the local LXD client doesn't have one configured.
# this also applies to locally installed LXD instances; we ALWAYS deploy against HTTPS (no unix socket).
if [[ "$(lxc remote get-default)" == "local" ]]; then
    echo "ERROR: LXC remote is set to local. ALL BCM activities are performed over HTTPS (even for local/standalone installs)."
    echo "   --- Consider creating a BCM cluster using 'bcm cluster create'."
    exit
fi

# provision and deprovision deploy and undeploy BCMBase which are critical data center components
# common to ALL BCM deployments. This includes bitcoind.
if [[ "$BCM_CLI_COMMAND" == "provision" || "$BCM_CLI_COMMAND" == "deprovision" ]]; then
    ./provision/entrypoint.sh "$@"
fi

if [[ "$BCM_CLI_COMMAND" == "tier" ]]; then
    ./tier/entrypoint.sh "$@"
fi

if [[ "$BCM_CLI_COMMAND" == "stack" ]]; then
    ./stack/entrypoint.sh "$@"
fi

if [[ "$BCM_CLI_COMMAND" == "show" ]]; then
    ./show.sh
fi

if [[ "$BCM_CLI_COMMAND" == "bitcoin-cli" ]]; then
    ./stack_cli/entrypoint.sh
fi
