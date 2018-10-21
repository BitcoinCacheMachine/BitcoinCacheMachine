
# First some notes about `./admin_machine_setup.sh`

`./admin_machine_setup.sh` prepares the `admin machine` for using BCM scripts. Here's what `./admin_machine_setup.sh` does to the `admin machine`:

* Creates the `~/.bcm/` directory - BCM scripts store LXD cluster, endpoint, and sensitive runtime files in this directory. `admin_machine_setup.sh` initializes ~/.bcm as a git repository for versioning. BCM scripts make regular commits to the ~/.bcm repo as files are added or deleted.
* (TODO:  ~/.bcm will be mounted using a encrypted [FUSE mount](https://github.com/netheril96/securefs) that can be unlocked interactively with a user-provided password or hardware wallet device).
* Generates the Root Certificate Authority cert at ~/.bcm/certs. Eventually, digital signatures associated with the public key will be relegated exclusively to hardware wallet operations.

Next, `./admin_machine_setup.sh` places the following lines in your `~/.bashrc` file so you can simply type `bcm` to load all relevant BCM environment variables for your active LXD endpoint. ('user' will be replaced with the user running ./admin_machine_setup.sh on the `admin machine`)

```bash
### Start BCM
export BCM_LOCAL_GIT_REPO="~/git/user/bcm"
alias bcm="source $BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh"
### END BCM
```

The `$BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh` script loads ALL BCM default environment variables, THEN loads the environment variables for the active LXD remote endpoint, if any.

## Getting Started

Run the following on your `admin machine`:

```bash
bash -c ./admin_machine_setup.sh  --- params
```

## Software Installation

`./admin_machine_setup.sh` then passes execution to the `./install_software.sh` script. This script installs the following software on the `admin machine`:

* [docker-ce](https://docs.docker.com/install/linux/docker-ce/ubuntu/) -- Docker is installed on the `admin machine` so we can run docker containers locally. This allows the BCM `admin machine` to function without having to install a bunch of new software on the machine.
* [ZFS](https://en.wikipedia.org/wiki/ZFS) - Used for LXC container storage backend.
* [LXD/LXC](https://linuxcontainers.org/lxd/introduction/) - LXD is installed on the `admin machine` so you can deploy BCM scripts locally for testing and development. 
* [mulitpass](https://github.com/CanonicalLtd/multipass) -- Multipass allows you to run QEMU/KVM-based virtual machines. Also useful for testing and development. Visit the [BCM multipass directory](../multipass/) for additional details.

## Software Configuration

In the final step, `./admin_machine_setup.sh` passes control to `./provision.sh`. This script primes the LXD configuration on your local `admin machine` to accept BCM scripts. `./provision.sh` configures your local LXD endpoint to operate in [clustering](https://lxd.readthedocs.io/en/latest/clustering/) mode. `./provision.sh`.

Once you have a properly configured LXD endpoint, delve into the [$BCM_LOCAL_GIT_REPO/lxd/](../lxd/) directory. This is where you can deploy BCM data center components to any cluster-mode LXD endpoint.
