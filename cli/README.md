# Bitcoin Cache Machine CLI

The only user interface to BCM is the Linux command line. BCM really is just a bunch of BASH scripts that are called by the program `./bcm` in this directory.  When you run `$BCM_GIT_DIR/setup.sh` as part of the [Getting Started Guide](https://github.com/BitcoinCacheMachine/BitcoinCacheMachine#getting-started), several lines are added to your `~/.bashrc` file. These lines make it so that your default terminal environment can find the CLI entrypoint `$BCM_GIT_DIR/cli/bcm`. To verify that your default environment variables are defined, run `bcm info` or consult `~/.bashrc`; bcm-related items are appended.

## Get an overview of your BCM CLI Environment

If the cli is configured correctly, you can `bcm info` to get an overview of your BCM environment. This command lists the following things:

* GNUPGHOME:              Directory that contains your Trezor-backed GPG certificates. 'N/A' if not set.
*  - CLUSTER_CERT_ID:        GPG Certificate ID
*  - CLUSTER_CERT_TITLE:     Satoshi Nakamoto <satoshi@bitcoin.org>
* PASSWORD_STORE_DIR:     Directory of your Trezor GPG-backed standard unix password manager store. 'N/A' if not set.
* ELECTRUM_DIR:           Directory containing user-facing Electrum wallet files. 'N/A' if not set.
* BCM_SSH_DIR:            Directory where SSH public keys (e.g., known_hosts) are placed. 'N/A' if not set.
* BCM_ACTIVE:             [0|1] - Set to 0 to switch the BCM context to your home directory. This will update the above directories to be in $HOME.
* BCM_DEBUG:              [0|1] - Whether the 'bcm' CLI should emit detailed information.
* BCM_DEFAULT_CHAIN:      All `bcm stack` commands are deployed against the active chain: "testnet", "mainnet", or "regtest".
* BCM_CLUSTER:            Current cluster under management;
* LXD_REMOTE:             Name of the cluster your LXD client is currently configured to target.
* BCM_LXD_IMAGE_CACHE:    If set, BCM will pull LXD images from this host.
* BCM_DOCKER_IMAGE_CACHE: If set, BCM will configure the Docker mirror cache to use this host instead of Docker Hub.

# BCM CLI Features

The BCM CLI provides several entrypoints into interacting with your Trezor. The `bcm --help` menu is the authoritative documentation for the CLI and is kept most up-to-date.

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
