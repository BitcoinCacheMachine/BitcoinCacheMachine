#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# download the main ubuntu image if it doesn't exist.
# if it does exist, it SHOULD be the latest image (due to auto-update).
if ! lxc image list --format csv | grep -q "bcm-lxc-base"; then
    # 'images' is the publicly avaialb e image server.
    # we will use it if the default of images.linuxcontainers.org is set in BCM_LXD_IMAGE_CACHE
    LXD_IMAGE_REMOTE="images"
    if [[ $BCM_LXD_IMAGE_CACHE != "images.linuxcontainers.org" ]]; then
        LXD_IMAGE_REMOTE="$BCM_LXD_IMAGE_CACHE"
        if ! lxc remote list --format csv | grep -q "$LXD_IMAGE_REMOTE"; then
            lxc remote add "$LXD_IMAGE_REMOTE" "$BCM_LXD_IMAGE_CACHE:8443"
        fi
    fi
    
    # download and export the LXC base image if it doesn't exist on disk.
    if ! lxc image list --format csv --columns l | grep -q "bcm-lxc-base"; then
        if [ -f "$BCM_CACHE_DIR/bcm-lxc-base" ]; then
            lxc image import "$BCM_CACHE_DIR/bcm-lxc-base" "$BCM_CACHE_DIR/bcm-lxc-base.root" --alias bcm-lxc-base
        else
            lxc image copy "$LXD_IMAGE_REMOTE:$BCM_LXC_BASE_IMAGE" "$(lxc remote get-default):" --alias bcm-lxc-base
            sleep 2
        fi
        
        # cache the image to disk at BOOTSTRAP DIR to avoid network IO
        if [ ! -f "$BCM_CACHE_DIR/bcm-lxc-base" ]; then
            lxc image export "bcm-lxc-base" "$BCM_CACHE_DIR/bcm-lxc-base"
        fi
    fi
    
fi


# the way we provision a network on a cluster of count 1 is DIFFERENT
# than one that's larger than 1.
if [[ $CLUSTER_NODE_COUNT -gt 1 ]]; then
    # we run the following command if it's a cluster having more than 1 LXD node.
    for ENDPOINT in $CLUSTER_ENDPOINTS; do
        lxc network create --target "$ENDPOINT" bcmbr0
    done
else
    if ! lxc network list --format csv | grep -q bcmbr0; then
        # but if it's just one node, we just create the network.
        lxc network create bcmbr0 ipv4.nat=true ipv6.nat=false
    fi
fi

# If there was more than one node, this is the last command we need
# to run to initiailze the network across the cluster. This isn't
# executed when we have a cluster of size 1.
if ! lxc network list --format csv | grep -q bcmbr0; then
    lxc network create bcmbr0
fi

if ! lxc list --format csv | grep -q "$LXC_BCM_BASE_IMAGE_NAME"; then
    echo "Creating host '$LXC_BCM_BASE_IMAGE_NAME'."
    lxc init bcm-lxc-base --network="bcmbr0" --profile="bcm-ssd" --profile="bcm-privileged" "$LXC_BCM_BASE_IMAGE_NAME"
fi


if lxc list --format csv -c=ns | grep "$LXC_BCM_BASE_IMAGE_NAME" | grep -q STOPPED; then
    lxc start "$LXC_BCM_BASE_IMAGE_NAME"
    sleep 5
    
    echo "Installing required software on LXC host '$LXC_BCM_BASE_IMAGE_NAME'."
    lxc exec "$LXC_BCM_BASE_IMAGE_NAME" -- apt-get update
    
    # docker.io is the only package that seems to work seamlessly with
    # storage backends. Using BTRFS since docker recognizes underlying file system
    lxc exec "$LXC_BCM_BASE_IMAGE_NAME" -- apt-get install -y --no-install-recommends docker.io wait-for-it ifmetric jq
    
    if [[ $BCM_DEBUG == 1 ]]; then
        lxc exec "$LXC_BCM_BASE_IMAGE_NAME" -- apt-get install --no-install-recommends -y nmap curl slurm tcptrack dnsutils tcpdump
    fi
    
    ## checking if this alleviates docker swarm troubles in lxc.
    #https://github.com/stgraber/lxd/commit/255b875c37c87572a09e864b4fe6dd05a78b4d01
    lxc exec "$LXC_BCM_BASE_IMAGE_NAME" -- touch /.dockerenv
    lxc exec "$LXC_BCM_BASE_IMAGE_NAME" -- mkdir -p /etc/docker
    
    # clean up the image before publication
    lxc exec "$LXC_BCM_BASE_IMAGE_NAME" -- apt-get autoremove -qq
    lxc exec "$LXC_BCM_BASE_IMAGE_NAME" -- apt-get clean -qq
    lxc exec "$LXC_BCM_BASE_IMAGE_NAME" -- rm -rf /tmp/*
    
    lxc exec "$LXC_BCM_BASE_IMAGE_NAME" -- systemctl stop docker
    lxc exec "$LXC_BCM_BASE_IMAGE_NAME" -- systemctl enable docker
    
    #stop the template since we don't need it running anymore.
    lxc stop "$LXC_BCM_BASE_IMAGE_NAME"
    
    lxc profile remove "$LXC_BCM_BASE_IMAGE_NAME" bcm-privileged
    lxc network detach bcmbr0 "$LXC_BCM_BASE_IMAGE_NAME"
fi

# Let's publish a snapshot. This will be the basis of our LXD image.
lxc snapshot "$LXC_BCM_BASE_IMAGE_NAME" bcmHostSnapshot

# publish the resulting image for other members of the LXD cluster (TODO)
echo "Publishing $LXC_BCM_BASE_IMAGE_NAME""/bcmHostSnapshot" "'$LXC_BCM_BASE_IMAGE_NAME' on cluster '$(lxc remote get-default)'."
lxc publish "$LXC_BCM_BASE_IMAGE_NAME/bcmHostSnapshot" --alias "$LXC_BCM_BASE_IMAGE_NAME"
