#!/bin/bash

cd /app

## provisioning script for proxyhost -- lxc pushes this directory to proxyhost then executes this script.
#docker pull minimum2scp/squid:latest
#docker run -d -p 3128:3128 minimum2scp/squid:latest

# we're assuming BCM environment variables are properly
# set by our provisioner at /etc/environment
source /etc/environment

# make it so all sessions share the proxy config (for debugging)
cat /etc/environment >> /root/.bashrc

docker stack deploy -c /app/mirror.yml mirror
