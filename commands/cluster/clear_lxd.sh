#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

DELETE_IMAGES=0

for i in "$@"; do
    case $i in
        --delete-images=*)
            DELETE_IMAGES="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done


if ! which jq >/dev/null 2>&1; then
    echo "This tool requires: jq"
    exit 1
fi

## Delete anything that's tied to a project
for project in $(lxc query "/1.0/projects?recursion=1" | jq .[].name -r); do
    echo "==> Deleting all containers for project: ${project}"
    for container in $(lxc query "/1.0/containers?recursion=1&project=${project}" | jq .[].name -r); do
        lxc delete --project "${project}" -f "${container}"
    done
    
    if [[ $DELETE_IMAGES == 1 ]]; then
        echo "==> Deleting all images for project: ${project}"
        for image in $(lxc query "/1.0/images?recursion=1&project=${project}" | jq .[].fingerprint -r); do
            lxc image delete --project "${project}" "${image}"
        done
    else
        echo "INFO: the '--all' flag was not specified, so any existing LXC images were NOT removed."
    fi
done

for project in $(lxc query "/1.0/projects?recursion=1" | jq .[].name -r); do
    echo "==> Deleting all profiles for project: ${project}"
    for profile in $(lxc query "/1.0/profiles?recursion=1&project=${project}" | jq .[].name -r); do
        if [ "${profile}" = "default" ]; then
            printf 'config: {}\ndevices: {}' | lxc profile edit --project "${project}" default
            continue
        fi
        lxc profile delete --project "${project}" "${profile}"
    done
    
    if [ "${project}" != "default" ]; then
        echo "==> Deleting project: ${project}"
        lxc project delete "${project}"
    fi
done

## Delete the networks
echo "==> Deleting all networks"
for network in $(lxc query "/1.0/networks?recursion=1" | jq '.[] | select(.managed) | .name' -r); do
    lxc network delete "${network}"
done

## Delete the storage pools
echo "==> Deleting all storage pools"
for storage_pool in $(lxc query "/1.0/storage-pools?recursion=1" | jq .[].name -r); do
    for volume in $(lxc query "/1.0/storage-pools/${storage_pool}/volumes/custom?recursion=1" | jq .[].name -r); do
        echo "==> Deleting storage volume ${volume} on ${storage_pool}"
        lxc storage volume delete "${storage_pool}" "${volume}"
    done
    
    ## Delete the custom storage volumes
    lxc storage delete "${storage_pool}"
done