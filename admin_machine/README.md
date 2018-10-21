
# First some notes about `./admin_machine_setup.sh`

`./admin_machine_setup.sh` prepares the `admin machine` for using BCM scripts. Here's what `./admin_machine_setup.sh` does to the `admin machine`:

* Creates the `~/.bcm/` directory - BCM scripts store LXD cluster, endpoint, and sensitive runtime files in this directory. `admin_machine_setup.sh` initializes ~/.bcm as a git repository for versioning. BCM scripts make regular commits to the ~/.bcm repo as files are added or deleted.
* (TODO:  ~/.bcm will be mounted using a encrypted [FUSE mount](https://github.com/netheril96/securefs) that can be unlocked interactively with a user-provided password or hardware wallet device).
* Generates the Root Certificate Authority cert at ~/.bcm/certs. Eventually, digital signatures associated with the public key will be relegated exclusively to hardware wallet operations.
* Places the following lines in your `~/.bashrc` file so you can simply type `bcm` to load all relevant BCM environment variables for your active LXD endpoint. The [`../lxd/`](../lxd/) directory relies heavily on BCM environment variables to guide execution of BCM scripts. The `$BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh` script loads ALL BCM default environment variables, THEN loads the environment variables for the active LXD remote endpoint, if any.

```bash
### Start BCM
export BCM_LOCAL_GIT_REPO="~/git/$(whoami)/bcm"
alias bcm="source $BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh"
```

* Passes control to `./install_software.sh` which installs the following software on the `admin machine`:
  1. [docker-ce](https://docs.docker.com/install/linux/docker-ce/ubuntu/) -- Docker is installed on the `admin machine` so we can run docker containers locally. This allows the BCM `admin machine` to function without having to install a bunch of new software on the machine.
  2. [ZFS](https://en.wikipedia.org/wiki/ZFS) - Used for LXC container storage backend.
  3. [LXD/LXC](https://linuxcontainers.org/lxd/introduction/) - LXD is installed on the `admin machine` so you can deploy BCM scripts locally for testing and development. 
  4. [mulitpass](https://github.com/CanonicalLtd/multipass) -- Multipass allows you to run QEMU/KVM-based virtual machines. Also useful for testing and development. Visit the [BCM multipass directory](../multipass/) for additional details.
* Configures the installed software for BCM. `./provision.sh` (called by `admin_machine_setup.sh`). This script primes the LXD configuration on your local `admin machine` to accept BCM scripts. It configures your local LXD endpoint to operate in [clustering](https://lxd.readthedocs.io/en/latest/clustering/) mode.

## Getting Started

Run the following on your `admin machine`:

```bash
bash -c ./admin_machine_setup.sh  --- params
```

Once you have a properly configured LXD endpoint (`lxc info` and `docker info`), delve into the [$BCM_LOCAL_GIT_REPO/lxd/](../lxd/) directory. This is where you can deploy BCM data center components to any cluster-mode LXD endpoint.