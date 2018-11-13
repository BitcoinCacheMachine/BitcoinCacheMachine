#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"
source ../host_template/defaults.sh
source ./defaults.sh

# if bcm-template lxc image exists, run the gateway template creation script.
if [[ -z $(lxc image list | grep "bcm-template") ]]; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default) creates or downloads a remote 'bcm-template'."
    exit
fi

./create_lxc_gateway_networks.sh

# create the 'bcm-gateway-profile' lxc profile
if [[ $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_CREATE = 1 ]]; then
    if [[ -z $(lxc profile list | grep "bcm-gateway-profile") ]]; then
        lxc profile create bcm-gateway-profile
    fi

    cat ./gateway_lxd_profile.yml | lxc profile edit bcm-gateway-profile
fi

# let's make sure we have the dockertemplate to init from.
if [[ -z $(lxc list | grep "$BCM_HOSTTEMPLATE_NAME") ]]; then
    echo "Error. LXC host '$BCM_HOSTTEMPLATE_NAME' doesn't exist."
    exit
fi

# We'll quit if the host is already there.
if [[ ! -z $(lxc list | grep "$BCM_GW_TEMPLATE_NAME") ]]; then
    echo "Error. LXC host '$BCM_GW_TEMPLATE_NAME' doesn't exist."
    exit
fi

# let's init the gateway; Let's make sure it deploys to the first node so we know
# where the snapshot data is going to be made.
export MASTER_GATEWAY_NAME="$BCM_LXC_GATEWAY_CONTAINER_NAME-01"
lxc init --target "$(lxc remote get-default)-01" $(lxc remote get-default):bcm-template $MASTER_GATEWAY_NAME -p bcm_default -p docker_privileged -p bcm-gateway-profile
lxc file push 10-lxc.yaml $MASTER_GATEWAY_NAME/etc/netplan/10-lxc.yaml
lxc storage volume create bcm_btrfs $BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME block.filesystem=ext4

MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
lxc storage volume attach bcm_btrfs $BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME $MASTER_GATEWAY_NAME dockerdisk path=/var/lib/docker
lxc file push daemon.json $MASTER_GATEWAY_NAME/etc/docker/daemon.json

lxc start $MASTER_GATEWAY_NAME

../shared/wait_for_dockerd.sh --container-name="$MASTER_GATEWAY_NAME"

#lxc exec $MASTER_GATEWAY_NAME -- ip route 

lxc exec $MASTER_GATEWAY_NAME -- docker pull registry:latest

lxc file push daemon1.json $MASTER_GATEWAY_NAME/etc/docker/daemon.json

lxc file push ./stacks/registry_mirror/ $MASTER_GATEWAY_NAME/root/stacks/ -p -r
lxc file push ./stacks/private_registry/ $MASTER_GATEWAY_NAME/root/stacks/ -p -r

lxc exec $MASTER_GATEWAY_NAME -- docker swarm init --advertise-addr 127.0.0.1 >> /dev/null

lxc restart $MASTER_GATEWAY_NAME

../shared/wait_for_dockerd.sh --container-name="$MASTER_GATEWAY_NAME"

lxc exec $MASTER_GATEWAY_NAME -- docker stack deploy -c /root/stacks/registry_mirror/registry_mirror.yml regmirror
lxc exec $MASTER_GATEWAY_NAME -- docker stack deploy -c /root/stacks/private_registry/private_registry.yml privateregistry

lxc exec $MASTER_GATEWAY_NAME -- wait-for-it -t 0 192.168.4.1:5000
lxc exec $MASTER_GATEWAY_NAME -- wait-for-it -t 0 192.168.4.1:443

sleep 10

lxc exec $MASTER_GATEWAY_NAME -- docker pull consul:1.4.0-rc1

lxc exec $MASTER_GATEWAY_NAME -- docker tag consul:1.4.0-rc1 bcm-consul:latest


# now let's build some custom images that we're going run on each bcm-gateway
# namely TOR
export BCM_DOCKER_BASE_IMAGE="ubuntu:bionic-20181018"

lxc exec $MASTER_GATEWAY_NAME -- docker pull $BCM_DOCKER_BASE_IMAGE
lxc exec $MASTER_GATEWAY_NAME -- docker tag $BCM_DOCKER_BASE_IMAGE bcm-bionic-base:latest
lxc file push ./stacks/bcm-base.Dockerfile $MASTER_GATEWAY_NAME/root/Dockerfile
lxc exec $MASTER_GATEWAY_NAME -- docker build -t bcm-base:latest .


lxc exec $MASTER_GATEWAY_NAME -- mkdir -p /root/stacks/tor
lxc file push ./stacks/tor/bcm-tor.Dockerfile $MASTER_GATEWAY_NAME/root/stacks/tor/Dockerfile
lxc file push ./stacks/tor/tor_socks5_dns.yml $MASTER_GATEWAY_NAME/root/stacks/tor/tor_socks5_dns.yml
lxc file push ./stacks/tor/torrc $MASTER_GATEWAY_NAME/root/stacks/tor/torrc

lxc exec $MASTER_GATEWAY_NAME -- docker build -t bcm-tor:latest /root/stacks/tor/
lxc exec $MASTER_GATEWAY_NAME -- docker tag bcm-tor:latest 192.168.4.1:443/bcm-tor:latest
lxc exec $MASTER_GATEWAY_NAME -- docker push 192.168.4.1:443/bcm-tor:latest
lxc exec $MASTER_GATEWAY_NAME -- docker stack deploy -c /root/stacks/tor/tor_socks5_dns.yml gwtor


# let's get a bcm-gateway LXC instance on each cluster endpoint.
MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    HOST_ENDING=$(echo $endpoint | tail -c 2)
    LXD_CONTAINER_NAME="bcm-gateway-$(printf %02d $HOST_ENDING)"

    echo "HOST_ENDING: $HOST_ENDING"
    echo "LXD_CONTAINER_NAME: $LXD_CONTAINER_NAME"
    if [[ $HOST_ENDING -ge 2 ]]; then
        lxc init --target $endpoint bcm-gateway-template $LXD_CONTAINER_NAME -p bcm_default -p docker_privileged -p bcm-gateway-profile
        lxc start $LXD_CONTAINER_NAME
    fi
done








# for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
#     #lxc file push daemon.json $BCM_LXC_GATEWAY_CONTAINER_NAME/etc/docker/daemon.json
#     echo "Running LXC STORAGE VOLUME CREATE on $endpoint"
    
# done

######### RUNTIME
#lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker run -d --name=dev-consul --net=host -e CONSUL_BIND_INTERFACE=eth1 bcm-consul:latest


# # disable systemd-resolved so don't have a conflict on port 53 when dnsmasq binds.
# lxc file push resolved.conf $BCM_LXC_GATEWAY_CONTAINER_NAME/etc/systemd/resolved.conf
# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- chown root:root /etc/systemd/resolved.conf
# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- chmod 0644 /etc/systemd/resolved.conf

# lxc restart $BCM_LXC_GATEWAY_CONTAINER_NAME

# ../shared/wait_for_dockerd.sh --container-name="$BCM_LXC_GATEWAY_CONTAINER_NAME"




# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker run --name dnsmasq -d --restart always --net=host --cap-add=NET_ADMIN bcm-dnsmasq:latest

# # now let's update gateway's dockerd daemon to use the mirror it itself is hosting.
# lxc file push finished.daemon.json $BCM_LXC_GATEWAY_CONTAINER_NAME/etc/docker/daemon.json

# lxc restart $BCM_LXC_GATEWAY_CONTAINER_NAME

# ../lxd/shared/wait_for_dockerd.sh --container-name="$BCM_LXC_GATEWAY_CONTAINER_NAME"

# bash -c ./stacks/up_lxc_gateway_stacks.sh






#lxc storage volume detach bcm_btrfs $BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME $BCM_LXC_GATEWAY_CONTAINER_NAME dockerdisk

#lxc storage volume snapshot bcm_btrfs $BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME gateway-baseline
