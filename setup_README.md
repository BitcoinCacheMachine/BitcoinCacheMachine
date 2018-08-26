# What ./setup.sh Does

`$BCM_LOCAL_GIT_REPO/setup.sh` is meant to be executed on the `admin machine` and affects ONLY the admin machine. Its purpose is to set up your Bitcoin Cache Machine `admin machine` environment. `./setup.sh`:

* Installs necessary client tools needed on the `admin machine` to properly deploy BCM components.
* Creates the `~/.bcm` directory - BCM scripts stores endpoint and runtime-specific files here. It is RECOMMENDED that ~/.bcm (and all its subdirectories) be placed under PRIVATE source control (e.g., private Keybase git repo) and be securely backed-up.
* Creates the ~/.bcm/endpoints directory - contains user-defined `LXD_ENDPOINT.env` files. Each file MUST be named the same as the LXD endpoint that it is meant to control. LXD remotes can be found by running the `lxc remote list` command on the `admin machine`. `./setup.sh` automatically creates `local.env` for the LXD remote running locally on the `admin machine`. The LXD daemon on the `admin machine` is NEVER exposed on the network, but is accessible by the local unix socket for testing and development.
* ~/.bcm/runtime - a directory to store runtime artifacts emitted by various BCM LXD shell scripts. This folder contains potentially sensitive files, such as cloud-init files with passwords and SHOULD be placed under source control and adequately protected.

All BCM LXD scripts ASSUME that BCM environment variables have been properly sourced PRIOR to being executed.  You can place the following in your `~/.bashrc` file so you can simply type `bcm` to load the `~/.bcm/defaults.env` and the `~/.bcm/endpoints/$(lxc remote get-default).env`.

```bash
# BCM
export BCM_LOCAL_GIT_REPO="git/github/BitcoinCacheMachine"
alias bcm='source ~/$BCM_LOCAL_GIT_REPO/resources/bcm/bashrc'
lxc remote set-default local
```

After updating ~/.bashrc with the above commands, you can source your BCM environment variables simply by typing `bcm` at the temrinal. To verify, type `env | grep BCM`.

```bash
BCM_INSTALL_BITCOIN_BITCOIND_TESTNET=true
BCS_INSTALL_RSYNCD=true
BCM_BITCOIN_BITCOIND_DOCKER_IMAGE=cachestack.lxd/bitcoind:16.1
BCM_INSTALL_BITCOIN_BITCOIND_TESTNET_BUILD=true
BCM_INSTALL_BITCOIN_LIGHTNINGD_TESTNET_BUILD=true
BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR=
BCM_BITCOIN_LIGHTNINGD_DOCKER_IMAGE=cachestack.lxd/lightningd:0.6
...
```