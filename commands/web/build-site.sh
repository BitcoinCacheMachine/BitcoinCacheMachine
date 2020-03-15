#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# this script creates


# mkdir -p $HOME/.aws

# if [ ! -f $HOME/.aws/bcm ]; then
#     aws ec2 create-key-pair --key-name bcm --query 'KeyMaterial' --output text > $HOME/.aws/bcm
# fi

# #chmod 0400 $HOME/.aws/bcm

# aws ec2 run-instances \
# --image-id ami-07d0cf3af28718ef8 \
# --count 1 \
# --instance-type t2.micro \
# --key-name bcm 


# #--security-group-ids sg-903004f8 \


# #--subnet-id subnet-6e7f829e

AWS_CLOUD_INIT_FILE=aws_docker_machine_cloud_init.yml

# creates a public VM in AWS and provisions the bcm website.
docker-machine create --driver amazonec2 \
--amazonec2-open-port 80 \
--amazonec2-open-port 443 \
--amazonec2-access-key $AWS_ACCESS_KEY \
--amazonec2-secret-key $AWS_SECRET_ACCESS_KEY \
--amazonec2-userdata $AWS_CLOUD_INIT_FILE \
--amazonec2-region us-east-1 registry

eval $(docker-machine env registry)

# enable swarm mode so we can deploy a stack.
docker swarm init

# if $HOME/.abot/registry.config doesn't exist, create a new one.
if [[ ! -f $HOME/.abot/registry.config ]]; then
    REGISTRY_HTTP_SECRET=$(apg -n 1 -m 30 -M CN)
    mkdir -p $HOME/.abot
    echo "REGISTRY_HTTP_SECRET="$REGISTRY_HTTP_SECRET >> $HOME/.abot/registry.config
else
    # if it does exist, source it.
    source $HOME/.abot/registry.config
fi


#private-registry-data

docker-machine ssh registry -- sudo apt-get update
docker-machine ssh registry -- sudo apt-get install -y software-properties-common add-apt-respository
docker-machine ssh registry -- sudo add-apt-repository ppa:certbot/certbot
docker-machine ssh registry -- sudo apt-get update
docker-machine ssh registry -- sudo apt-get -y install certbot

docker-machine ssh registry -- mkdir -p /home/ubuntu/registry/<FIXME>
docker-machine ssh registry -- sudo certbot certonly --webroot -w /home/ubuntu/registry/<FIXME> -d <FIXME>.com -d registry.<FIXME>.com

env REGISTRY_HTTP_SECRET=$REGISTRY_HTTP_SECRET docker stack deploy -c registry.yml registry

wait-for-it -t 0 $(docker-machine ip registry):80
