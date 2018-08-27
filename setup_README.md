# What ./setup.sh Does

`$BCM_LOCAL_GIT_REPO/setup.sh` is meant to be executed on the `admin machine` and affects ONLY the admin machine. Its purpose is to set up your Bitcoin Cache Machine `admin machine` environment. `./setup.sh`:

* Installs necessary client tools needed on the `admin machine` to properly deploy BCM components.
* Creates the `~/.bcm` directory - BCM scripts store LXD endpoint and runtime files in this directory. BCM scripts automatically place ~/.bcm under git source control and make regular commits when the directory changes. This directory SHOULD be securely backed-up. Planned features are to encrypt the data in ~/.bcm using a encrypted [FUSE mount](https://github.com/netheril96/securefs) that can be unlocked with the appropriate Trezor-provided password.
* Creates the ~/.bcm/endpoints directory - contains user-defined `LXD_ENDPOINT.env` files. Each file MUST be named the same as the LXD endpoint that it is meant to control. LXD remotes can be found by running the `lxc remote list` command on the `admin machine`. `./setup.sh` automatically creates `local.env` for the LXD remote running locally on the `admin machine`. The LXD daemon on the `admin machine` is NEVER exposed on the network, but is accessible by the local unix socket for testing and development.
* ~/.bcm/runtime - a directory to store runtime artifacts emitted by various BCM LXD shell scripts. This folder contains potentially sensitive files, such as cloud-init files with passwords and SHOULD be placed under source control and adequately protected.

All BCM LXD scripts (any scripts with "_lxd_" in the name) ASSUME that BCM environment variables have been properly sourced PRIOR to being executed.

```REPEAT!!! All BCM '_lxd_' scripts are EXECUTED AGAINST THE ACTIVE LXD REMOTE!!!```

`./setup.sh` places the following lines in your `~/.bashrc` file so you can simply type `bcm` to load all relevant BCM environment variables. ('user' would be replaced with the active username on the `admin machine`)

```bash
### Start BCM
export BCM_LOCAL_GIT_REPO="/home/user/git/github/BitcoinCacheMachine"
alias bcm="source $BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh"
lxc remote set-default local
### END BCM
```

You can inspect `$BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh` to see what happens. That script starts by loading ALL BCM default environment variables, THEN loads the environment variables for the active LXD remote endpoint.