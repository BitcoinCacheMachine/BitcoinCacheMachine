
# First some notes about `./up_dev_machine.sh`

The `dev machine` is NOT meant to participate in production workloads. It is typically a laptop or desktop machine that you use on a day-to-day basis. It's meant primarily for development and testing of your BCM configurations. The `dev machine` is distinct from the `admin_machine`, which acts as the secure BCM management plane for operational clusters (future work).

`./up_dev_machine.sh` prepares the `dev machine` for using BCM scripts. It is meant to be executed on a freshly installed Ubuntu 18.04. Here's what `./up_dev_machine.sh` does to the `dev machine`:

* Creates the `~/.bcm/` directory - BCM scripts store LXD cluster, endpoint, and sensitive runtime files in this directory. `up_dev_machine.sh` initializes ~/.bcm as a git repository for versioning. BCM scripts make regular commits to the ~/.bcm repo as files are added or deleted.
* (TODO:  ~/.bcm will be mounted using a encrypted [FUSE mount](https://github.com/netheril96/securefs) that can be unlocked interactively with a user-provided password or hardware wallet device).
* Generates the Root Certificate Authority cert at ~/.bcm/certs. Eventually, digital signatures associated with the public key will be relegated exclusively to hardware wallet operations.
* Places the following line in your `~/.bashrc` file so BCM shell scripts can invoke scripts by fully qualified path.  The [`../lxd/`](../lxd/) directory relies heavily on BCM environment variables to guide execution of BCM scripts. The `$BCM_LOCAL_GIT_REPO/resources/bcm/1admin_load_bcm_env.sh` script loads ALL BCM default environment variables, THEN loads the environment variables for the active LXD remote endpoint, if any.

```bash
### Start BCM
export BCM_LOCAL_GIT_REPO="~/git/<USER>/bcm"
```
* Similar to above, `./up_dev_machine.sh` exports the BCM_LOCAL_GIT_REPO variable so the current shell knows where to locate BCM scripts.
* Passes control to `./install_software.sh` which installs the following software on the `dev machine`:
  1. [docker-ce](https://docs.docker.com/install/linux/docker-ce/ubuntu/) -- Docker is installed on the `dev machine` so docker containers be run locally (future work). Note that BCM infrastructure components are spawned in separate dockerd instances than the one listed here (those nested within LXC system containers).
  2. [ZFS](https://en.wikipedia.org/wiki/ZFS) - Used for LXC system container storage backend. dockerd instances inside each LXC system container are redirected to distinct directory-based storage pool. Future BCM versions will work to software-define the dockerd storage backend using [CEPH](https://en.wikipedia.org/wiki/Ceph_(software)).
  3. [LXD/LXC](https://linuxcontainers.org/lxd/introduction/) - LXD is installed on the `dev machine` so you can deploy BCM scripts locally for testing and development. The `dev machine` is configured to NOT LISTEN on the network by default.
  4. [mulitpass](https://github.com/CanonicalLtd/multipass) - Multipass allows you to run QEMU/KVM-based virtual machines. Extremely useful for testing and development purposes. Visit the [BCM multipass directory](../multipass/) for additional details.
* Configures the installed software for BCM. `./provision.sh` (called by `up_dev_machine.sh`). This script primes the LXD configuration on your local `dev machine` to accept BCM scripts. It configures your local LXD endpoint to operate in [clustering](https://lxd.readthedocs.io/en/latest/clustering/) mode with a node count of one.

## Getting Started

Run the following on your `dev machine`:

```bash
./up_dev_machine.sh
```

## Verification

Verify that `./up_dev_machine.sh` did what it was supposed to do. Run the following commands to do some checking:

```bash
# view the remotes, (local) should be the default
lxc remote list

# ensure local dev lxd endpoint is configured in cluster-mode: server_clustered SHOULD be 'true'
lxc info

# view the cluster members, should list a fully operational DEV_MACHINE listening at https://127.0.0.1:8443
lxc cluster list
```

You can inspect the `~/.bcm/DEV_MACHINE/` directory to view the files that were created. There should be a `lxd_endpoints/local/lxd/preseed.yml` file at the very least.

To continue this tutorial, jump over to the [$BCM_LOCAL_GIT_REPO/lxd/lxd/](../lxd/) directory to start deploying BCM infrastructure components to your local `dev machine`.

Once you have a properly configured LXD endpoint (`lxc info` and `docker info`), delve into the [$BCM_LOCAL_GIT_REPO/lxd/](../lxd/) directory. This is where you can deploy BCM data center components to any cluster-mode LXD endpoint.