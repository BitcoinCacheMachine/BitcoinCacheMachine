#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE="${2:-}"
if [ ! -z "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a command."
    cat ./help.txt
    exit
fi

if [[ "$#" -lt 3 ]]; then
    cat ./help.txt
    exit
fi

BCM_DIR=
BCM_CHAIN=

for i in "$@"; do
    case $i in
        bcmdir=*)
            BCM_DIR="${i#*=}"
            shift # past argument=value
        ;;
        chain=*)
            BCM_CHAIN="${i#*=}"
            shift # past argument=value
        ;;
        *) ;;
        
    esac
done

if [[ $BCM_CLI_VERB == "get" ]]; then
    OBJECT="${3:-}"
    if [[ $OBJECT == chain ]]; then
        if [ "$(lxc remote get-default)" != "local" ]; then
            BCM_CHAIN=$(lxc project list | grep "(current)" | awk '{print $2}')
            
            if [[ $BCM_CHAIN != "default" ]]; then
                echo "$BCM_CHAIN"
            else
                echo "$BCM_DEFAULT_CHAIN"
            fi
        else
            echo "$BCM_DEFAULT_CHAIN"
        fi
        
        elif [[ $OBJECT == bcmdir ]]; then
        echo "$BCM_RUNTIME_DIR"
    fi
fi

if [[ $BCM_CLI_VERB == "set" ]]; then
    if [[ ! -z $BCM_CHAIN ]]; then
        # make sure the user has sent in a valid command; quit if not.
        if [[ $BCM_CHAIN != "regtest" && $BCM_CHAIN != "testnet" && $BCM_CHAIN != "mainnet" ]]; then
            echo "Error: The valid commands for 'regtest', 'testnet', and 'mainnet'."
            exit
        fi
        
        # only do something if the user is actually changing chains.
        if ! lxc project list | grep "(current)" | awk '{print $2}' | grep -q "$BCM_CHAIN"; then
            # make sure we're on the right remove
            if ! lxc project list | grep -q "$BCM_CHAIN"; then
                lxc project create "$BCM_CHAIN" -c features.images=false -c features.profiles=false
            fi
            
            lxc project switch "$BCM_CHAIN"
            echo "You are now targeting '$BCM_CHAIN'"
        fi
    fi
    
    if [[ ! -z $BCM_DIR ]]; then
        if [[ ! -d $BCM_DIR ]]; then
            echo "ERROR: directory '$BCM_DIR' does not exist."
            exit
        fi
        
        echo "export BCM_RUNTIME_DIR=$BCM_DIR" >> "$BCM_CONFIG_FILE"
    fi
fi
