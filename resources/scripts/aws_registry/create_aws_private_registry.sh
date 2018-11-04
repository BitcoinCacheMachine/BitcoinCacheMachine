#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

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

# if ~/.abot/registry.config doesn't exist, create a new one. 
if [[ ! -f ~/.abot/registry.config ]]; then
    REGISTRY_HTTP_SECRET=$(apg -n 1 -m 30 -M CN)
    mkdir -p ~/.abot
    echo "REGISTRY_HTTP_SECRET="$REGISTRY_HTTP_SECRET >> ~/.abot/registry.config
else
    # if it does exist, source it.
    source ~/.abot/registry.config
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
