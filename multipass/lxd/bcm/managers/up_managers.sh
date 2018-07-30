
#!/bin/bash

# quit script if any erros are found
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# Managernet is used by any docker host that joins the swarm.
echo "Creating managernet."
lxc network create managernet ipv4.address=10.0.0.1/24 ipv4.nat=false ipv6.nat=false


# create the storage pool if it doesn't exist.
if [[ -z $(lxc storage list | grep "$BC_ZFS_POOL_NAME") ]]; then
  lxc storage create "$BC_ZFS_POOL_NAME" zfs size=10GB
else
  echo "$BC_ZFS_POOL_NAME already exists, skipping pool creation."
fi

## Create the manager1 host from the lxd image template.
lxc init bctemplate manager-template -p docker -p dockertemplate_profile -s $BC_ZFS_POOL_NAME

# push necessary files to the template including daemon.json
lxc file push ./daemon.json manager-template/etc/docker/daemon.json

# create a snapshot from which all production managers will be based.
lxc snapshot manager-template "managerTemplate"

## Start and configure the managers.
# create manager1

lxc profile create manager1
cat ./lxd_profiles/manager1.yml | lxc profile edit manager1

lxc copy manager-template/managerTemplate manager1
lxc profile apply manager1 docker,manager1

# Create an LXC storage volume of type 'dir' then mount it at /var/lib/docker in the container.
lxc storage create manager1-dockervol dir
lxc config device add manager1 dockerdisk disk source=$(lxc storage show manager1-dockervol | grep source | awk 'NF>1{print $NF}') path=/var/lib/docker 

lxc start manager1

# wait for the machine to start
# TODO find a better way to wait
sleep 10


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


