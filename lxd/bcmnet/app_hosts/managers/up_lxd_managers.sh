
#!/bin/bash

# quit script if any erros are found
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# for outbound NAT in case services on manager1 need to access a cachestack
echo "Creating lxdbrManager1."
lxc network create lxdbrManager1

# Managernet is used by any docker host that joins the swarm hosted by the managers.
echo "Creating lxd network 'managernet' for swarm members."
lxc network create managernet ipv4.address=10.0.0.1/24 ipv4.nat=false ipv6.nat=false

# # create the storage pool if it doesn't exist.
# if [[ -z $(lxc storage list | grep "$bcm_d1ata") ]]; then
#   lxc storage create "$bcm_d1ata" zfs size=10GB
# fi

# create the docker profile if it doesn't exist. This may happen when we have an external cachestack 
# and we didn't create the profile during the host_template creation.
if [[ -z $(lxc profile list | grep docker) ]]; then
  lxc profile create docker
  cat ../../bcs/host_template/docker_lxd_profile.yml | lxc profile edit docker
fi


# create the docker_privileged profile if it doesn't exist, which might happen when we're using an external cachestack
if [[ -z $(lxc profile list | grep "docker_privileged") ]]; then
  lxc profile create docker_privileged
  cat ../../bcs/host_template/lxd_profile_docker_template.yml | lxc profile edit docker_privileged
fi

## Create the manager1 host from the lxd image template.
lxc init bcm-template manager-template -p docker -p docker_privileged -s "$BCM_ZFS_PREFIX-bcm_d1ata"

# push necessary files to the template including daemon.json
lxc file push ./daemon.json manager-template/etc/docker/daemon.json

# create a snapshot from which all production managers will be based.
lxc snapshot manager-template "managerTemplate"

## Start and configure the managers.
# create manager1

lxc profile create manager1
cat ./lxd_profiles/manager1.yml | lxc profile edit manager1

lxc copy manager-template/managerTemplate manager1
lxc profile apply manager1 default,manager1

if [[ -z $(lxc storage list | grep "manager1-dockervol") ]]; then
  # Create an LXC storage volume of type 'dir' then mount it at /var/lib/docker in the container.
  lxc storage create manager1-dockervol dir
fi

# attach the dockerdisk to manager1 assuming 'manager1-dockervol' exists.
## TODO AND it's not already attached.
if [[ $(lxc storage list | grep "manager1-dockervol") ]]; then
  lxc config device add manager1 dockerdisk disk source="$(lxc storage show manager1-dockervol | grep source | awk 'NF>1{print $NF}')" path=/var/lib/docker 
fi


lxc start manager1

# wait for the machine to start
# TODO find a better way to wait
sleep 10

lxc exec manager1 -- ifmetric eth0 0

lxc exec manager1 -- docker swarm init --advertise-addr=10.0.0.11 >/dev/null

echo "Waiting for manager1 docker swarm service."

sleep 5

echo "Creating /apps/kafka inside manager1."
lxc exec manager1 -- mkdir -p /apps/kafka





echo "Deploying zookeeper and kafka to the swarm."
lxc file push ./kafka/zookeeper1.yml manager1/apps/kafka/zookeeper1.yml
lxc exec manager1 -- docker stack deploy -c /apps/kafka/zookeeper1.yml kafka

echo "Deploying a Kafka broker to the swarm."
lxc file push ./kafka/kafka1.yml manager1/apps/kafka/kafka1.yml
lxc exec manager1 -- docker stack deploy -c /apps/kafka/kafka1.yml kafka

echo "Deploying Kafka schema-registry to the swarm."
lxc file push ./kafka/schema-registry.yml manager1/apps/kafka/schema-registry.yml
lxc exec manager1 -- docker stack deploy -c /apps/kafka/schema-registry.yml kafka

echo "Deploying Kafka schema-registry-ui to the swarm."
lxc file push ./kafka/schema-registry-ui.yml manager1/apps/kafka/schema-registry-ui.yml
lxc exec manager1 -- docker stack deploy -c /apps/kafka/schema-registry-ui.yml kafka

echo "Deploying Kafka rest to the swarm."
lxc file push ./kafka/kafka-rest.yml manager1/apps/kafka/kafka-rest.yml
lxc exec manager1 -- docker stack deploy -c /apps/kafka/kafka-rest.yml kafka

echo "Deploying Kafka topics-ui to the swarm."
lxc file push ./kafka/kafka-topics-ui.yml manager1/apps/kafka/kafka-topics-ui.yml
lxc exec manager1 -- docker stack deploy -c /apps/kafka/kafka-topics-ui.yml kafka

echo "Deploying logstash to the swarm configured for gelf on TCP 12201."
lxc file push ./kafka/gelf-listener.yml manager1/apps/kafka/gelf-listener.yml
lxc file push ./kafka/logstash.conf manager1/apps/kafka/logstash.conf
lxc exec manager1 -- docker stack deploy -c /apps/kafka/gelf-listener.yml gelf
