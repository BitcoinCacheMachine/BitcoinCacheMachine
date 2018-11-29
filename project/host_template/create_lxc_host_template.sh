#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if lxc list --format csv -c n | grep -q "bcm-lxc-base"; then
    echo "The LXD image 'bcm-lxc-base' doesn't exist. Exiting."
    exit
fi


# the way we provision a network on a cluster of count 1 is DIFFERENT
# than one that's larger than 1.
if [[ $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME" | wc -l) -gt 1 ]]; then
    # we run the following command if it's a cluster having more than 1 LXD node.
    for ENDPOINT in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
        lxc network create --target "$ENDPOINT" bcmbr0
    done
else
    # but if it's just one node, we just create the network.
    lxc network create bcmbr0 ipv4.nat=true ipv6.nat=false
fi

# If there was more than one node, this is the last command we need
# to run to initiailze the network across the cluster. This isn't 
# executed when we have a cluster of size 1.
if lxc network list | grep bcmbr0 | grep -q PENDING; then
    lxc network create bcmbr0 ipv4.nat=true ipv6.nat=false
fi

echo "Creating host 'bcm-host-template' which is what ALL BCM LXC system containers are based on."
lxc init bcm-lxc-base -p bcm_default -p docker_privileged -n bcmbr0 bcm-host-template

lxc start bcm-host-template

sleep 5

# TODO provide configuration item to route these requests over local TOR proxy
echo "Installing required software on LXC host 'bcm-host-template'."
lxc exec bcm-host-template -- apt-get update

# docker.io is the only package that seems to work seamlessly with
# storage backends. Using BTRFS since docker recognizes underlying file system
lxc exec bcm-host-template -- apt-get install docker.io wait-for-it -qq

if [[ $BCM_DEBUG = 1 ]]; then
    lxc exec bcm-host-template -- apt-get install jq nmap curl ifmetric slurm tcptrack dnsutils tcpdump -qq
fi



## checking if this alleviates docker swarm troubles in lxc.
#https://github.com/stgraber/lxd/commit/255b875c37c87572a09e864b4fe6dd05a78b4d01
lxc exec bcm-host-template -- touch /.dockerenv
lxc exec bcm-host-template -- mkdir -p /etc/docker

# this helps suppress some warning messages.  TODO
lxc file push ./sysctl.conf bcm-host-template/etc/sysctl.conf
lxc exec bcm-host-template -- chmod 0644 /etc/sysctl.conf

# clean up the image before publication
lxc exec bcm-host-template -- apt-get autoremove -qq
lxc exec bcm-host-template -- apt-get clean -qq
lxc exec bcm-host-template -- rm -rf /tmp/*

lxc exec bcm-host-template -- systemctl stop docker
lxc exec bcm-host-template -- systemctl enable docker

#stop the template since we don't need it running anymore.
lxc stop bcm-host-template
lxc profile remove bcm-host-template docker_privileged
lxc network detach bcmbr0 bcm-host-template
#lxc network delete bcmbr0

# echo "Creating a snapshot of the lxd host 'dockertemplate' called 'bcmHostSnapshot'."
lxc snapshot bcm-host-template bcmHostSnapshot

# if instructed, serve the newly created snapshot to trusted LXD hosts.
if lxc list | grep -q "bcm-host-template"; then
    echo "Publishing bcm-host-template/bcmHostSnapshot 'bcm-template' on cluster '$(lxc remote get-default)'."
    lxc publish bcm-host-template/bcmHostSnapshot --alias bcm-template
fi