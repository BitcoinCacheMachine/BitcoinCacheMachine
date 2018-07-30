
#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# quit if the user didn't supply an endpoint name.
if [[ -z $1 ]]; then
  echo "Usage: 'source ./bcm_env.sh LXD_ENDPOINT_HOSTNAME'"
  exit 0
fi

LXD_ENDPOINT=$1

echo "Setting Bitcoin Cache Machine environment variable defaults."

# Multipass options
export MULTIPASS_VM_NAME=""
export MULTIPASS_DISK_SIZE="50G"
export MULTIPASS_MEM_SIZE="4G"
export MULTIPASS_CPU_COUNT="4"

# Bitcoin Cache Machine and Cache Stack options
export BC_ATTACH_TO_UNDERLAY="false"
export BC_CACHESTACK_STANDALONE="false"

# if BC_ATTACH_TO_UNDERLAY=true, this physical interface will macvlan the interface
# to get network underlay access.
export BCS_TRUSTED_HOST_INTERFACE=""


# Cache Stack installation options.
export BCS_INSTALL_BITCOIND_TESTNET="false"
export BCS_INSTALL_BITCOIND_MAINNET="false"
export BCS_INSTALL_IPFSCACHE="false"
export BCS_INSTALL_PRIVATEREGISTRY="false"
export BCS_INSTALL_REGISTRYMIRRORS="false"
export BCS_INSTALL_SQUID="false"
export BCS_INSTALL_TOR_SOCKS5_PROXY="false"

# BCM specific options.

# If there is a standalone cachestack installed on the network, you can specify it here.
# whatever you put here MUST be defined as an LXD endpoint on the administrative machine.
export BCM_EXTERNAL_CACHESTACK_LXD_ENDPOINT="none"

# BCM installation and deployment options.
export BCM_DEPLOYMENT_IPFS_BOOTSTRAP="false"
export BCM_INSTALL_BITCOIN_BITCOIND="false"
export BCM_INSTALL_BITCOIN_LIGHTNINGD="false"
export BCM_INSTALL_BITCOIN_LND="false"


## debugging
export BC_LXD_IMAGE_BCTEMPLATE_DELETE="false"
export BC_HOST_TEMPLATE_DELETE="false"
export BC_DELETE_CACHESTACK="false"
export BCM_DISABLE_DOCKER_GELF="false"


# secret data
# todo seed based on hardware wallet standard.
export BC_LXD_SECRET="CHANGETHIS"

# shouldn't need to change
export BC_ZFS_POOL_NAME="bc_data"

echo "Setting LXD endpoint-specific environment variables for '$LXD_ENDPOINT'."

# multipass-based bitcoin cache stack.
if [[ $LXD_ENDPOINT = "bcm01" ]]; then
  echo "Sourcing ./endpoints/bcm01.sh."
  source ./endpoints/bcm01.sh
fi

# for staging/antsle
if [[ $LXD_ENDPOINT = "staging" ]]; then
  echo "Sourcing ./endpoints/staging.sh."
  source ./endpoints/staging.sh
fi

# for local lxd daemon
if [[ $LXD_ENDPOINT = "local" ]]; then
  echo "Sourcing ./endpoints/local.sh."
  source ./endpoints/local.sh
fi

if [[ $(lxc remote list | grep "$LXD_ENDPOINT") ]]; then
  lxc remote set-default $LXD_ENDPOINT
fi
