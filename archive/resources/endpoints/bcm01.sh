#!/bin/bash

export MULTIPASS_VM_NAME="bcm01"
export MULTIPASS_DISK_SIZE="100G"
export MULTIPASS_MEM_SIZE="4G"
export MULTIPASS_CPU_COUNT="4"


export BC_ATTACH_TO_UNDERLAY="true"
export BC_LXD_SECRET="bcm01secret"
export BC_CACHESTACK_STANDALONE="false"

# ens3 connects to the underlay
export BCS_TRUSTED_HOST_INTERFACE="ens3"

# BCS applications on bcm01
export BCS_INSTALL_BITCOIND_TESTNET="true"
export BCS_INSTALL_BITCOIND_MAINNET="true"
export BCS_INSTALL_IPFSCACHE="true"
export BCS_INSTALL_PRIVATEREGISTRY="true"
export BCS_INSTALL_REGISTRYMIRRORS="true"
export BCS_INSTALL_SQUID="true"
export BCS_INSTALL_TOR_SOCKS5_PROXY="true"


# BCM installation and deployment options.
#export BCM_DEPLOYMENT_IPFS_BOOTSTRAP="false"
export BCM_INSTALL_BITCOIN_BITCOIND="true"
export BCM_INSTALL_BITCOIN_LIGHTNINGD="true"
export BCM_INSTALL_BITCOIN_LND="true"


#export BC_LXD_IMAGE_BCTEMPLATE_DELETE="true"
#export BC_HOST_TEMPLATE_DELETE="true"
#export BC_DELETE_CACHESTACK="true"
export BCM_DISABLE_DOCKER_GELF="true"
