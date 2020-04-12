#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

## Delete anything that's tied to a project
for project in $(lxc query "/1.0/projects?recursion=1" | jq .[].name -r); do
    for container in $(lxc query "/1.0/containers?recursion=1&project=${project}" | jq .[].name -r); do
        echo "==> Deleting container '${container}' for project '${project}'"
        lxc delete --project "${project}" -f "${container}"
    done
    
    if [[ $ALL_FLAG == 1 ]]; then
        for image in $(lxc query "/1.0/images?recursion=1&project=${project}" | jq .[].fingerprint -r); do
            FINGERPRINT=${image:0:12}
            if ! lxc image list --format csv --columns lf | grep "$FINGERPRINT" | grep -q "bcm-lxc-base"; then
                echo "==> Deleting image ${FINGERPRINT} for project: ${project}"
                lxc image delete --project "${project}" "${image}"
            fi
        done
    fi
done

for project in $(lxc query "/1.0/projects?recursion=1" | jq .[].name -r); do
    for profile in $(lxc query "/1.0/profiles?recursion=1&project=${project}" | jq .[].name -r); do
        if [ "${profile}" = "default" ]; then
            printf 'config: {}\ndevices: {}' | lxc profile edit --project "${project}" default
            continue
        fi
        echo "==> Deleting profile 'profile'."
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
    
    
    if [ ! $(echo "$storage_pool" | grep -q bcm) ] || [ "$ALL_FLAG" = "1" ]; then
        ## Delete the custom storage volumes
        echo "==> Deleting storage pool '${storage_pool}'"
        lxc storage delete "${storage_pool}"
    else
        echo "INFO: Skipping the bcm-lxc-base (Ubuntu focal amd64), else we have to redownload."
    fi
done