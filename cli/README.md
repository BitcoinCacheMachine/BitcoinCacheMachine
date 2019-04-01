# Bitcoin Cache Machine CLI

The only user interface to BCM is the Linux command line. BCM really is just a bunch of BASH scripts that you call from the command line. This directory contains the code related to the BCM CLI. When you run `$BCM_GIT_DIR/setup.sh` as part of the Getting Started guide, sevearal lines are added to your `~/.bashrc` file. These lines make it so that your default terminal environment can find the CLI entrypoint (./bcm). To verify that your default environment variables are defined, run `bcm info`.  

## Get an overview of your BCM CLI Environment

If the cli is configured correctly, you can `bcm info` to get an overview of your BCM environment. This command lists the following things:

* GNUPGHOME:              Directory that contains your Trezor-backed GPG certificates.
*  - CLUSTER_CERT_ID:        GPG Certificate ID
*  - CLUSTER_CERT_TITLE:     Satoshi Nakamoto <satoshi@bitcoin.org>
* PASSWORD_STORE_DIR:     Directory of your Trezor GPG-backed standard unix password manager store.
* BCM_SSH_DIR:            Directory where your SSH public keys are stored.
* BCM_ACTIVE:             [0|1] - whether the 'bcm' environment should use the ~/.bcm directory or revert to using your home directory (~/.gnupg and ~/.password_store)
* BCM_DEBUG:              [0|1] - Whether the 'bcm' CLI should emit detailed information.
* LXD_REMOTE:             Name of the cluster your LXD client is currently configured to target.
* BCM_LXD_IMAGE_CACHE:    If set, BCM will pull LXD images from this host.
* BCM_DOCKER_IMAGE_CACHE: If set, BCM will configure the Docker mirror cache to use this host instead of Docker Hub.
* BCM_DEFAULT_CHAIN:      Default is testnet. Change this environment variable and BCM will deploy components to that chain. Valid values are "testnet", "mainnet", and "regtest".

## Get an overview of your LXD configuration

Use the `bcm show` command to get an overview of your LXD container configuation. This command simply outputs various `lxd show` commands so you can get a snapshot view of your LXC/LXD configuration. The following resources are displayed:

* LXC Hosts/containers
* LXC Networks
* LXC Storage Pools
* LXD Storage Volumes for pool bcm_btrfs
* LXC Profiles
* LXD Daemon config
* LXD Images
* LXC Cluster
* LXD Projects


# BCM Versioning

Various BCM versions are defined in ./env, which is available to all BCM scripts. The format is as following:

```bash
#            vLTS.FEATURE.SYSTEM.APP
BCM_VERSION="v0.0.0.0"
```

LTS:        Changes in major LTS REQUIRE a full-backup of user data to off-site storage, complete redeployment of your BCM infrastructure including base OS, and recovery of data. LTS updates use Disaster Recovery methodology (see below).
FEATURE:    Changes to the system that DO NOT require updates to the underlying host OS but represent major feature releases.
SYSTEM:     If a version changes a the SYSTEM level, all LXD System-level container and associated LXD resources (e.,g., profiles, volumes, networks) are created and old versions of resources are culled.
APP:        Changes here require a rebuilding and redeployment of any docker-based image (app-level containers).

The current GIT tag of $BCM_GIT_DIR defines the authoritative current version number.  


# Definitions

## System Data

System data are LXD-related resources such as containers, networks, profiles, and volume definitions. This data is NOT necessary to retain since it is effectively generated from the BCM git repo code.

## User Data

User data is any data that is generated from app-level containers. Examples include the contents of bcm_btrfs volumes ending in '-docker'. User data is expected to be backed up using Local-HA and Lightning-enabled decentralized storage (TBD).

# Disaster Recovery Methodology

BCM is a distributed system and works to maintain local high availability of user data. In addition, BCM works to ensure that all data is fully backed up off-site. THe goal is to implement a system that backs user-data up to a decentralized storage service. Once a Lightning-enables services comes out on the Bitcoin Blockchain, it will be integrated.

When A Disaster Recovery occurs, A completely new BCM infrastructure is deployed from sctrach.  After the new version is deployed and BEFORE user-services are started, data is recovered from the decentralized storage service. Once data is restored, app-level services are started.