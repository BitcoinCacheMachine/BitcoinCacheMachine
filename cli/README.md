# BItcoin Cache Machine CLI

The only user interface to BCM is through the Linux command line. BCM really is just a bunch of BASH scripts that you call from the command line. This directory contains the code related to the BCM CLI. $BCM_GIT_DIR/setup.sh configures your SDN controller by adding lines to your ~/.bashrc file. These lines make it so that your default terminal has a number of environment variables defined.  You can find list these environment variables with `env | grep BCM`. This will return a list of BCM-related environment variables that are active in your current shell.  

## Get an overview of your BCM CLI Environment

If the cli is configured correctly, you can `bcm info` to get an overview of your BCM environment. This command lists the following things:

* GNUPGHOME:              Directory that contains your Trezor-backed GPG certificates.
** CLUSTER_CERT_ID:              GPG Certificate ID
** CLUSTER_CERT_TITLE:           Satoshi Nakamoto <satoshi@bitcoin.org>
* PASSWORD_STORE_DIR:         Directory of your standard unix password manager store.
* BCM_ACTIVE:                 [0|1] - whether the 'bcm' environment should use the ~/.bcm directory or
                                      revert to using your home directory (~/.gnupg and ~/.password_store)
* BCM_DEBUG:                  [0|1] - Whether the 'bcm' CLI should output additional output info.
* BCM_CACHESTACK:             [hostname] - DNS name of LXD image cache and/or docker mirror registy.
* LXD_CLUSTER:                Name of the cluster your LXD client is configured to target.

## Get an overview of your LXD configuration

Use the `bcm show` command to get an overview of your LXD container configuation. This command simply outputs various `lxd show` commands so you can get a snapshot view of your LXC/LXD configuration. The following resources are displayed:

* LXC Hosts
* LXC Networks
* LXC Storage Pools
* LXD Storage Volumes for pool bcm_btrfs
* LXC Profiles
* LXD Daemon config
* LXD Images
* LXC Cluster
* LXD Projects
* LXD client Remotes
