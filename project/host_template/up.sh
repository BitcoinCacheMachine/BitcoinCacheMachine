#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"

echo "Starting 'up_lxc_host_template.sh'."

BCM_REBUILD_TEMPLATE=0
# first, let's check to see if our end proudct -- namely our LXC image with alias 'bcm-template'
# if it exists, we will quit by default, UNLESS the user has passed in an override, in which case
# it (being the lxc image 'bcm-template') will be rebuilt.
if lxc image list --format csv | grep -q "bcm-template"; then
	if $BCM_REBUILD_TEMPLATE -eq 1; then
		echo "TODO: implement rebuild logic"
	else
		echo "LXC image bcm-template exists and BCM_REBUILD_TEMPLATE was not set. The existing image will not be modified."
		exit
	fi
fi

# download the main ubuntu image if it doesn't exist.
# if it does exist, it SHOULD be the latest image (due to auto-update).
if ! lxc image list --format csv | grep -q "bcm-lxc-base"; then
	echo "Copying the ubuntu/cosmic lxc image from the public 'image:' server to '$(lxc remote get-default):bcm-lxc-base'"
	lxc image copy images:ubuntu/cosmic "$(lxc remote get-default):" --alias bcm-lxc-base --auto-update
fi

function createProfile() {
	PROFILE_NAME=$1

	# create the profile if it doesn't exist.
	if ! lxc profile list | grep -q "$PROFILE_NAME"; then
		lxc profile create "$PROFILE_NAME"
	fi

	echo "Applying $PROFILE_NAME to lxc profile '$PROFILE_NAME'."
	lxc profile edit "$PROFILE_NAME" <"./lxd_profiles/$PROFILE_NAME.yml"
}

if lxc profile list | grep -q "bcm_default"; then
	createProfile bcm_default
fi

# create the docker_unprivileged profile
createProfile docker_unprivileged

# create the docker_privileged profile
createProfile docker_privileged

if lxc list --format csv -c n | grep -q "bcm-lxc-base"; then
	echo "The LXD image 'bcm-lxc-base' doesn't exist. Exiting."
	exit
fi

# the way we provision a network on a cluster of count 1 is DIFFERENT
# than one that's larger than 1.
if [[ $(bcm cluster list --endpoints | wc -l) -gt 1 ]]; then
	# we run the following command if it's a cluster having more than 1 LXD node.
	for ENDPOINT in $(bcm cluster list --endpoints); do
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
lxc exec bcm-host-template -- apt-get install docker.io wait-for-it ifmetric -qq

if [[ $BCM_DEBUG == 1 ]]; then
	lxc exec bcm-host-template -- apt-get install jq nmap curl slurm tcptrack dnsutils tcpdump -qq
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

# echo "Creating a snapshot of the lxd host 'dockertemplate' called 'bcmHostSnapshot'."
lxc snapshot bcm-host-template bcmHostSnapshot

# if instructed, serve the newly created snapshot to trusted LXD hosts.
if lxc list | grep -q "bcm-host-template"; then
	echo "Publishing bcm-host-template/bcmHostSnapshot 'bcm-template' on cluster '$(lxc remote get-default)'."
	lxc publish bcm-host-template/bcmHostSnapshot --alias bcm-template
fi
