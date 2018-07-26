#!/bin/bash

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# quit if the BCM environment variables havne't been loaded.
if [[ $(env | grep BCM) = '' ]] 
then
  echo "BCM variables not set. Please source a .env file."
  exit 1
fi

# if we're inside a VM, we assume LXD is not configured. 
# This sets to default config for BCM.
if [[ $BCM_ENVIRONMENT = 'vm' ]]; then
# set lxd to defaults
cat <<EOF | lxd init --preseed
config:
cluster: null
networks:
- name: lxdbr0
  type: bridge
  config:
    ipv4.address: auto
    ipv6.address: none
EOF

fi

#lxc list >>/dev/null

if [[ $BCM_CACHE_STACK = 'gw' ]]; then
  # set BCM_CACHE_STACK_IP to the gateway
  export BCM_CACHE_STACK_IP=$(/sbin/ip route | awk '/default/ { print $3 }')
elif [[ $BCM_CACHE_STACK = "none" ]]; then
  echo "No BCM cache stack specified. Data will be downloaded from the Internet."
else
  echo "Setting BCM_CACHE_STACK_IP=$BCM_CACHE_STACK"
  export BCM_CACHE_STACK_IP=$BCM_CACHE_STACK
fi

# if BCM_CACHE_STACK_IP has a value set, configure the rest of the env vars
if [[ ! -z $BCM_CACHE_STACK_IP ]]; then

  # configure the LXD daemon to obtain images from the BCM CACHE Stack
  if [[ -z $(lxc remote list | grep lxdcache) ]]; then
    echo "Adding lxd image server $BCM_CACHE_STACK_IP:8443"
    lxc remote add lxdcache ${BCM_CACHE_STACK_IP} --public --accept-certificate
    echo "Coping a cloud-based Ubuntu 18.04 image from the LXD daemon on ${BCM_CACHE_STACK_IP}:8443"
    lxc image copy lxdcache:bcm-bionic local: --alias bcm-bionic
  fi


  export BCM_REGISTRY_PROXY_REMOTEURL=http://${BCM_CACHE_STACK_IP}:5000
  export BCM_ELASTIC_REGISTRY_PROXY_REMOTEURL=http://${BCM_CACHE_STACK_IP}:5020

  # set HTTP and HTTPS proxy environment variables
  export HTTP_PROXY=${BCM_CACHE_STACK_IP}
  export HTTPS_PROXY=${BCM_CACHE_STACK_IP}

else
  if [[ $BCM_INSTALLATION != 'cachestack' ]]; then
    echo "BCM_CACHE_STACK not specified. LXD Image Cache not configured. Ubuntu 18.04 LXD will be downloaded from the Internet."
    
    echo "Clearing lxd proxy_http. HTTP requests made by LXD will be downloaded from the Internet."
    lxc config set core.proxy_http ""
    
    echo "Clearing lxd proxy_https. HTTPS requests made by LXD will be downloaded from the Internet."
    lxc config set core.proxy_https ""

    lxc config set core.proxy_ignore_hosts ""
  fi
fi


##############################################

# clone the host_template repo, which is shared with Cache Stack
git clone https://github.com/farscapian/bcm_host_template

echo "Creating an LXD system container template."
chmod +x ./bcm_host_template/up_host_template.sh
./bcm_host_template/up_host_template.sh

# proxyhost is mandatory for each BCM instance
echo "Deploying proxyhost."
./proxyhost/up_proxyhost.sh

# a manager is required for each BCM instance.
# TODO add more managers across independent hardware
echo "Creating manager hosts."
./managers/up_managers.sh

# Bitcoin infrastructure is required. Will probably implement some kind of primary/backup
# configuration for the trusted bitcoin full node.
echo "Deploying Bitcoin infrastructure."
./bitcoin/up_bitcoin.sh

  # # echo "deploying an elastic infrastructure."
  # ./elastic/up_elastic.sh

