# Bitcoin Cache Machine CLI

The only user interface to BCM is the Linux command line. BCM really is just a bunch of BASH scripts that are called by the program `./bcm` in this directory.  When you run `$BCM_GIT_DIR/setup.sh` as part of the [Getting Started Guide](https://github.com/BitcoinCacheMachine/BitcoinCacheMachine#getting-started), several lines are added to your `~/.bashrc` file. These lines make it so that your default terminal environment can find the CLI entrypoint `$BCM_GIT_DIR/cli/bcm`. To verify that your default environment variables are defined, run `bcm info` or consult `~/.bashrc`; bcm-related items are appended. `env | grep "BCM"` may also yield results.

## Get an overview of your BCM CLI Environment

If the cli is configured correctly, you can run `bcm info` to get an overview of your BCM environment:

* GNUPGHOME:              Directory that contains your Trezor-backed GPG certificates. 'N/A' if not set.
*  - CLUSTER_CERT_ID:        GPG Certificate ID
*  - CLUSTER_CERT_TITLE:     Satoshi Nakamoto <satoshi@bitcoin.org>
* PASSWORD_STORE_DIR:     Directory of your Trezor GPG-backed standard unix password manager store. 'N/A' if not set.
* ELECTRUM_DIR:           Directory containing user-facing Electrum wallet files. 'N/A' if not set.
* BCM_SSH_DIR:            Directory where SSH public keys (e.g., known_hosts) are placed. 'N/A' if not set.
* BCM_VERSION:            The version of BCM that the CLI is configured to target.
* BCM_ACTIVE:             [0|1] - Set to 0 to switch the BCM context to your home directory. This will update the above directories to be in $HOME.
* BCM_DEBUG:              [0|1] - Whether the 'bcm' CLI should emit detailed information.
* BCM_CHAIN:      All `bcm stack` commands are deployed against the active chain: "testnet", "mainnet", or "regtest". BCM_CHAIN is used in defining [LXD projects](https://github.com/lxc/lxd/blob/master/doc/projects.md), which allows you to deploy distinct data centers on common hardware.
* BCM_CLUSTER:            Current cluster under management.
* BCM_LXD_IMAGE_CACHE:    If set, BCM will pull LXD images from this host.
* BCM_DOCKER_IMAGE_CACHE: If set, BCM will configure the Docker mirror cache to use this host instead of Docker Hub.

# BCM CLI Features

The BCM CLI provides several entrypoints into interacting with your Trezor. The `bcm --help` menu is the authoritative documentation for the CLI and is kept most up-to-date.

You can switch your identity by setting `export BCM_ACTIVE=0` in your environment. When BCM_ACTIVE=0, the BCM CLI uses the folders found under $HOME to look for certificate and password stores. This allows you to generate multiple Trezor-backed public key GPG certificates and switch between them as needed. It is recommended that each identity be confined to a distinct [BIP032 path](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki) (i.e., Trezor passphrase).

## Get an overview of your LXD configuration

Use the `bcm show` command to get an overview of your LXD container configuation. This command simply outputs various `lxd show` commands so you can get a snapshot view of your LXC/LXD configuration. The following resources are displayed:

* LXC Hosts/containers      # filtered on active project
* LXC Networks              
* LXC Storage Pools
* LXD Storage Volumes
* LXC Profiles
* LXD Daemon config
* LXD Images
* LXC Cluster
* LXD Projects

## Stack Level commands

When you deploy BCM stacks using the `bcm stack start` command, certain commands MAY become available. For example, after you run `bcm stack start bitcoind`, the `bcm bitcoin-cli` command will become available. The BCM CLI automatically routes your CLI request to the appropriate app-level container. Trying running `bcm bitcoin-cli getnetworkinfo` to view bitcoind network output, or trying the `getblockchaininfo` to see where you are in the chain!  All commands are confined to your current bcm CLI CHAIN (`bcm get-chain`. 

If you want to start deploying mainnet infrastructure, you can run `bcm set-chain`, and all subsequent bcm commands will target that chain. Note that currently, there is total data-center separation between regtest, testnet, and mainnet modes of operation.
