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

NEW_RUNTIME_DIR=
BCM_CHAIN=
NEW_DATACENTER_NAME=
NEW_DEBUG_VAL=
NEW_CLUSTER_NAME=

for i in "$@"; do
    case $i in
        runtime-dir=*)
            NEW_RUNTIME_DIR="${i#*=}"
            shift # past argument=value
        ;;
        cluster=*)
            NEW_CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        chain=*)
            BCM_CHAIN="${i#*=}"
            shift # past argument=value
        ;;
        datacenter=*)
            NEW_DATACENTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        debug=*)
            NEW_DEBUG_VAL="${i#*=}"
            shift # past argument=value
        ;;
        *) ;;
        
    esac
done

if [[ $BCM_CLI_VERB == "get" ]]; then
    OBJECT="${3:-}"
    if [[ $OBJECT == chain ]]; then
        echo "$BCM_ACTIVE_CHAIN"
        elif [[ $OBJECT == "runtime-dir" ]]; then
        echo "$BCM_RUNTIME_DIR"
        elif [[ $OBJECT == datacenter ]]; then
        echo "$BCM_DATACENTER"
        elif [[ $OBJECT == debug ]]; then
        echo "$BCM_DEBUG"
    fi
    
    if [[ $OBJECT == cluster ]]; then
        lxc remote get-default
    fi
fi

if [[ $BCM_CLI_VERB == "set" ]]; then
    if [[ ! -z $BCM_CHAIN ]]; then
        # make sure the user has sent in a valid command; quit if not.
        if [[ $BCM_CHAIN != "regtest" && $BCM_CHAIN != "testnet" && $BCM_CHAIN != "mainnet" ]]; then
            echo "Error: The valid commands for 'regtest', 'testnet', and 'mainnet'."
            exit
        fi
        
        echo "export BCM_ACTIVE_CHAIN=$BCM_CHAIN" >> "$BCM_CONFIG_FILE"
    fi
    
    if [[ ! -z $NEW_RUNTIME_DIR ]]; then
        if [[ ! -d $NEW_RUNTIME_DIR ]]; then
            echo "ERROR: directory '$NEW_RUNTIME_DIR' does not exist."
            exit
        fi
        
        echo "export BCM_RUNTIME_DIR=$NEW_RUNTIME_DIR" >> "$BCM_CONFIG_FILE"
    fi
    
    if [[ ! -z $NEW_DATACENTER_NAME ]]; then
        echo "export BCM_DATACENTER=$NEW_DATACENTER_NAME" >> "$BCM_CONFIG_FILE"
    fi
    
    if [[ ! -z $NEW_DEBUG_VAL ]]; then
        echo "export BCM_DEBUG=$NEW_DEBUG_VAL" >> "$BCM_CONFIG_FILE"
    fi
    
    if [[ ! -z $NEW_CLUSTER_NAME ]]; then
        if lxc remote list --format csv | grep -q "$NEW_CLUSTER_NAME"; then
            if [[ "$NEW_CLUSTER_NAME" != "$(lxc remote get-default)" ]]; then
                lxc remote switch "$NEW_CLUSTER_NAME"
                echo "Your active BCM cluster is now set to target '$NEW_CLUSTER_NAME'."
            else
                echo "BCM is already targeting cluster '$NEW_CLUSTER_NAME'."
            fi
        else
            echo "Error: the LXC remote for BCM Cluster '$NEW_CLUSTER_NAME' is not defined."
        fi
    fi
fi

if [[ $BCM_CLI_VERB == "show" ]]; then
    bcm info
fi