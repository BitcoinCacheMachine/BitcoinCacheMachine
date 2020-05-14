#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

REMOVE_STORAGE=0
DELETE_CACHE=0
UNINSTALL_LXD=0

for i in "$@"; do
    case $i in
        --storage)
            REMOVE_STORAGE=1
            shift
        ;;
        --cache)
            DELETE_CACHE="${i#*=}"
            shift
        ;;
        --lxd)
            UNINSTALL_LXD="${i#*=}"
            shift
        ;;
        *)
            # unknown option
        ;;
    esac
done

# install LXD
if [[ -f "$(command -v lxc)" ]]; then
    
    source ./env
    
    if lxc list --format csv | grep -q "$BCM_VM_NAME"; then
        lxc delete "$BCM_VM_NAME" --force
    fi
    
    ## Delete anything that's tied to a project
    for project in $(lxc query "/1.0/projects?recursion=1" | jq .[].name -r); do
        for container in $(lxc query "/1.0/containers?recursion=1&project=${project}" | jq .[].name -r); do
            echo "==> Deleting container '${container}' for project '${project}'"
            lxc delete --project "${project}" -f "${container}"
        done
        
        
        for image in $(lxc query "/1.0/images?recursion=1&project=${project}" | jq .[].fingerprint -r); do
            FINGERPRINT=${image:0:12}
            if ! lxc image list --format csv --columns lf | grep "$FINGERPRINT" | grep -q "bcm-lxc-base"; then
                if ! lxc image list --format csv --columns lf | grep "$FINGERPRINT" | grep -q "bcm-vm-base"; then
                    echo "==> Deleting image ${FINGERPRINT} for project: ${project}"
                    lxc image delete --project "${project}" "${image}"
                fi
            fi
            
            if [[ $REMOVE_STORAGE == 1 ]]; then
                echo "==> Deleting image ${FINGERPRINT} for project: ${project}"
                lxc image delete --project "${project}" "${image}"
            fi
        done
        
    done
    
    for project in $(lxc query "/1.0/projects?recursion=1" | jq .[].name -r); do
        for profile in $(lxc query "/1.0/profiles?recursion=1&project=${project}" | jq .[].name -r); do
            if [ "${profile}" = "default" ]; then
                printf 'config: {}\ndevices: {}' | lxc profile edit --project "${project}" default
                continue
            fi
            echo "==> Deleting profile '${profile}'."
            lxc profile delete --project "${project}" "${profile}"
        done
        
        if [ "${project}" != "default" ]; then
            echo "==> Deleting project: ${project}"
            lxc project delete "${project}"
        fi
    done
    
    ## Delete the networks
    for network in $(lxc query "/1.0/networks?recursion=1" | jq '.[] | select(.managed) | .name' -r); do
        echo "==> Deleting network '$network'."
        lxc network delete "${network}"
    done
    
    ## Delete the storage pools
    for storage_pool in $(lxc query "/1.0/storage-pools?recursion=1" | jq .[].name -r); do
        for volume in $(lxc query "/1.0/storage-pools/${storage_pool}/volumes/custom?recursion=1" | jq .[].name -r); do
            echo "==> Deleting storage volume ${volume} on ${storage_pool}"
            lxc storage volume delete "${storage_pool}" "${volume}"
        done
        
        echo "==> Deleting storage pool '${storage_pool}'"
        lxc storage delete "${storage_pool}"
    done
fi

if [ $UNINSTALL_LXD = 1 ]; then
    sudo snap remove lxd
fi

if [ $REMOVE_STORAGE = 1 ]; then
    # delete the loop files.
    # TODO ADD COMMAND LINE PARAM
    for LOOP_FILE in hdd sd ssd; do
        if [ -f "$HOME/bcm-$LOOP_FILE.img" ]; then
            FILE_PATH="$HOME/bcm-$LOOP_FILE.img"
            CHOICE=0
            read -rp "WARNING: Are you sure you want to delete the file '$FILE_PATH'.? (y/n):  "   CHOICE
            echo $CHOICE
            
            if [ $CHOICE = y ]; then
                rm -f "$HOME/bcm-$LOOP_FILE.img"
            fi
        fi
    done
fi

if [ $DELETE_CACHE = 1 ]; then
    # delete locally cached files.
    if [ -d "$HOME/.local/bcm" ]; then
        rm -rf "$HOME/.local/bcm"
    fi
fi