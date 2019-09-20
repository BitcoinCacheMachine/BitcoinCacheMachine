#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if ! lxc project list --format csv | grep -q "default (current)"; then
    lxc project switch default
fi

# first, let's check to see if our end proudct -- namely our LXC image with alias 'bcm-template'
# if it exists, we will quit by default, UNLESS the user has passed in an override, in which case
# it (being the lxc image 'bcm-template') will be rebuilt.
if lxc image list --format csv | grep -q "$LXC_BCM_BASE_IMAGE_NAME"; then
    echo "INFO: LXC image '$LXC_BCM_BASE_IMAGE_NAME' has already been built."
fi

# create the docker_unprivileged profile
if ! lxc profile list --format csv | grep -q "docker_unprivileged"; then
    lxc profile create docker_unprivileged
    cat ./lxd_profiles/docker_unprivileged.yml | lxc profile edit docker_unprivileged
fi

# create the docker_privileged profile
if ! lxc profile list --format csv | grep -q "docker_privileged"; then
    lxc profile create docker_privileged
    cat ./lxd_profiles/docker_privileged.yml | lxc profile edit docker_privileged
fi

# if the default storage driver doesn't exist, create it.
if ! lxc storage list --format csv | grep -q "bcm"; then
    lxc storage create bcm btrfs
fi

# create the docker_unprivileged profile
if ! lxc profile list  --format csv | grep -q "bcm_disk"; then
    lxc profile create bcm_disk
    cat ./lxd_profiles/bcm_disk.yml | lxc profile edit bcm_disk
fi

if lxc list --format csv -c n | grep -q "bcm-lxc-base"; then
    echo "The LXD image 'bcm-lxc-base' doesn't exist. Exiting."
    exit
fi

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
    
    LXC_BASE_VERSION="18.04"
    echo "Copying the ubuntu/$LXC_BASE_VERSION lxc image from LXD image server '$LXD_IMAGE_REMOTE:' server to '$(lxc remote get-default):bcm-lxc-base'"
    lxc image copy "$LXD_IMAGE_REMOTE:ubuntu/$LXC_BASE_VERSION" "$(lxc remote get-default):" --alias bcm-lxc-base --auto-update
fi


# the way we provision a network on a cluster of count 1 is DIFFERENT
# than one that's larger than 1.
if [[ $(bcm cluster list endpoints | wc -l) -gt 1 ]]; then
    # we run the following command if it's a cluster having more than 1 LXD node.
    for ENDPOINT in $(bcm cluster list endpoints); do
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
if lxc network list --format csv | grep bcmbr0 | grep -q PENDING; then
    lxc network create bcmbr0 ipv4.nat=true ipv6.nat=false
fi

# if our image is not prepared, let's go ahead and create it.
if lxc image list --format csv | grep -q "$LXC_BCM_BASE_IMAGE_NAME"; then
    echo "The image '$LXC_BCM_BASE_IMAGE_NAME' is already published."
    exit
fi

if ! lxc list --format csv | grep -q "$LXC_BCM_BASE_IMAGE_NAME"; then
    echo "Creating host '$LXC_BCM_BASE_IMAGE_NAME'."
    lxc init bcm-lxc-base -p bcm_disk -p docker_privileged -n bcmbr0 "$LXC_BCM_BASE_IMAGE_NAME"
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
    
    lxc profile remove "$LXC_BCM_BASE_IMAGE_NAME" docker_privileged
    lxc network detach bcmbr0 "$LXC_BCM_BASE_IMAGE_NAME"
fi

# Let's publish a snapshot. This will be the basis of our LXD image.
lxc snapshot "$LXC_BCM_BASE_IMAGE_NAME" bcmHostSnapshot

# publish the resulting image
# other members of the LXD cluster will be able to pull and run this image
echo "Publishing $LXC_BCM_BASE_IMAGE_NAME""/bcmHostSnapshot" "'$LXC_BCM_BASE_IMAGE_NAME' on cluster '$(lxc remote get-default)'."
lxc publish "$LXC_BCM_BASE_IMAGE_NAME/bcmHostSnapshot" --alias "$LXC_BCM_BASE_IMAGE_NAME"


if lxc image list --format csv | grep -q "$LXC_BCM_BASE_IMAGE_NAME"; then
    lxc delete "$LXC_BCM_BASE_IMAGE_NAME"
fi
