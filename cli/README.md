# Bitcoin Cache Machine CLI

The only user interface to BCM is the Linux command line. BCM really is just a bunch of BASH scripts that are called by the program `./bcm` in this directory.  When you run `$BCM_GIT_DIR/setup.sh` as part of the [Getting Started Guide](https://github.com/BitcoinCacheMachine/BitcoinCacheMachine#getting-started), several lines are added to your `~/.bashrc` file. These lines make it so that your default terminal environment can find the CLI entrypoint `$BCM_GIT_DIR/cli/bcm`. To verify that your default environment variables are defined, run `bcm info` or consult `~/.bashrc`; bcm-related items are appended.

## Get an overview of your BCM CLI Environment

If the cli is configured correctly, you can `bcm info` to get an overview of your BCM environment. This command lists the following things:

* GNUPGHOME:              Directory that contains your Trezor-backed GPG certificates.
*  - CLUSTER_CERT_ID:        GPG Certificate ID
*  - CLUSTER_CERT_TITLE:     Satoshi Nakamoto <satoshi@bitcoin.org>
* PASSWORD_STORE_DIR:     Directory of your Trezor GPG-backed standard unix password manager store.
* ELECTRUM_DIR:           Directory containing user-facing Electrum wallet files.
* BCM_SSH_DIR:            Directory where SSH public keys (e.g., known_hosts) are placed.
* BCM_ACTIVE:             [0|1] - whether the 'bcm' environment should use the ~/.bcm directory or revert to using your home directory (~/.gnupg and ~/.password_store)
* BCM_DEBUG:              [0|1] - Whether the 'bcm' CLI should emit detailed information.
* BCM_DEFAULT_CHAIN:      All `bcm stack` commands are deployed against the active chain: "testnet", "mainnet", or "regtest".
* BCM_CLUSTER:            Current cluster under management;
* LXD_REMOTE:             Name of the cluster your LXD client is currently configured to target.
* BCM_LXD_IMAGE_CACHE:    If set, BCM will pull LXD images from this host.
* BCM_DOCKER_IMAGE_CACHE: If set, BCM will configure the Docker mirror cache to use this host instead of Docker Hub.


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

Various BCM versions are defined in ./env, which is available to all BCM scripts via the active signed git tag of `$BCM_GIT_DIR`. The format is as following:

```bash
# vLTS.SYSTEM.APP
BCM_VERSION="v0.0.0"
```

LTS:        Changes in major LTS REQUIRE a full-backup of user data to off-site storage, complete redeployment of your BCM infrastructure including base OS, and recovery of data. LTS updates use Disaster Recovery methodology (see below).
SYSTEM:     If a version changes a the SYSTEM level, all LXD System-level container and associated LXD resources (e.,g., profiles, volumes, networks) are created and old versions of resources are culled.
APP:        Changes here require a rebuilding and redeployment of any docker-based image (app-level containers).

The current GIT tag of $BCM_GIT_DIR defines the authoritative current version number.

# Definitions

## System Data

System data are LXD-related resources such as containers, networks, profiles, and volume definitions. This data is NOT necessary to retain since it is effectively generated from the BCM git repo code.

## User Data

User data is any data that is generated from app-level containers. Examples include the contents of bcm_btrfs volumes ending in '-docker'. User data is expected to be backed up using Local-HA and Lightning-enabled decentralized storage (TBD). User data consists of static file data contained in docker volumes and logging data collected by managed by the Kafka stack.

# Disaster Recovery Methodology

BCM is a distributed system and works to maintain local high availability of user data. In addition, BCM works to ensure that all data is fully backed up off-site to achieve disaster recovery. The goal is to implement a system that backs-up user-data to a decentralized storage service that accepts Bitcoin Lightning payments (future work).

When a Disaster Recovery occurs, a completely new BCM infrastructure is deployed from sctrach. After the new version is deployed and BEFORE user-services are started, data is recovered from the decentralized storage service. Once data is restored, app-level services are started. New keys GPG keys will be required since new infrastructure is being deployed.