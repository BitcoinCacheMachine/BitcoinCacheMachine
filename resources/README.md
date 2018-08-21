# Resources

`~/git/github/bcm/setup.sh` creates the following directories:

1. ~/.bcm - contains other directories and `defaults.env` which contains all BCM default environment variables. It is RECOMMENDED that ~/.bcm (and all its subdirectories) be placed under PRIVATE source control (e.g., private Keybase git repo) and be securely backed-up.
2. ~/.bcm/endpoints - directory contains user-defined `{LXD_ENDPOINT}.env` files. Each file MUST be named the same as the LXD endpoint that it is meant to control. LXD remotes can be found by running the `lxc remote list` command on the `admin machine`. `./setup.sh` automatically creates `local.env` for the LXD remote running locally on the `admin machine`.
3. ~/.bcm/runtime - a directory to store runtime artifacts emitted by various BCM LXD shell scripts. This folder contains potentially sensitive files, such as cloud-init files with passwords.

All BCM LXD scripts ASSUME that BCM environment variables have been properly sourced PRIOR to being executed.  You can place the following in your `~/.bashrc` file so you can simply type `bcm` to load the `~/.bcm/defaults.env` and the `~/.bcm/endpoints/$(lxc remote get-default).env`.

```bash
#  function that load the BCM environment variables for the active lxd remote.
function loadBCMEnvironment ()
{
	# load the environment variables for the current LXD remote.
	echo "Loading default BCM environment variables at ~/.bcm/defaults.env"
	source ~/.bcm/defaults.env

	echo "Overriding BCM default variables with those defined in ~/.bcm/endpoints/$(lxc remote get-default).env."
	source ~/.bcm/endpoints/"$(lxc remote get-default)".env
}

alias bcm="loadBCMEnvironment"
source ~/.bcm/defaults.env
```

After updating ~/.bashrc with the above commands, you can source your BCM environment variables simply by typing `bcm`. To verify, type `env | grep BC`.

```bash
BCM_INSTALL_BITCOIN_BITCOIND_TESTNET=true
BCS_INSTALL_RSYNCD=true
BC_HOST_TEMPLATE_DELETE=true
BCM_BITCOIN_BITCOIND_DOCKER_IMAGE=cachestack.lxd/bitcoind:16.1
BCM_INSTALL_BITCOIN_BITCOIND_TESTNET_BUILD=true
BCM_INSTALL_BITCOIN_LIGHTNINGD_TESTNET_BUILD=true
BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR=
BCM_BITCOIN_LIGHTNINGD_DOCKER_IMAGE=cachestack.lxd/lightningd:0.6
...
```