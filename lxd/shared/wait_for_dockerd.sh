#!/usr/bin/env bash


set -eu

BCM_LXC_CONTAINER_NAME=

for i in "$@"
do
case $i in
    --container-name=*)
    BCM_LXC_CONTAINER_NAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done


echo "Waiting for dockerd to come online on LXC host '$BCM_LXC_CONTAINER_NAME'"

if [[ $(lxc list | grep $BCM_LXC_CONTAINER_NAME) ]]; then
    while true; do
        if [[ $(lxc exec $BCM_LXC_CONTAINER_NAME -- systemctl is-active docker) == "active" ]]; then
            break
        fi

        sleep 1
        printf "."
    done
fi