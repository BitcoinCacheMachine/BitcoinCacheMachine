
# First some notes about `./up_dev_machine.sh`

The `dev machine` is NOT meant to participate in production workloads. It is typically a laptop or desktop machine that you use on a day-to-day basis. It's meant primarily for development and testing of your BCM configurations. The `dev machine` is distinct from the `admin machine`, which acts as the secure BCM management plane for operational clusters (future work).

`./up_dev_machine.sh` prepares the `dev machine` for using BCM scripts. It is meant to be executed on a freshly installed Ubuntu 18.04 (Server or Desktop should work) Here's what `./up_dev_machine.sh` does to the `dev machine`:

* Creates the `$BCM_RUNTIME_DIR/` directory - BCM scripts store LXD cluster, endpoint, and sensitive runtime files in this directory. `up_dev_machine.sh` initializes $BCM_RUNTIME_DIR as a git repository for versioning. BCM scripts make regular commits to the $BCM_RUNTIME_DIR repo as files are added or deleted.
* (TODO:  $BCM_RUNTIME_DIR will be mounted using a encrypted [FUSE mount](https://github.com/netheril96/securefs) that can be unlocked interactively with a user-provided password or hardware wallet device).
* Generates the Root Certificate Authority cert at $BCM_RUNTIME_DIR/certs. Eventually, digital signatures associated with the public key will be relegated exclusively to hardware wallet operations.
* Places the following line in your `$HOME/.bashrc` file so BCM shell scripts can invoke dependent scripts by fully qualified path.

```bash
### Start BCM
export BCM_LOCAL_GIT_REPO_DIR="$HOME/git/<USER>/bcm"
```
* Similar to above, `./up_dev_machine.sh` exports the BCM_LOCAL_GIT_REPO_DIR variable so the current shell knows where to locate BCM scripts.
* Passes control to `./install_software.sh` which installs the following software on the `dev machine`:
  1. [docker-ce](https://docs.docker.com/install/linux/docker-ce/ubuntu/) -- Docker is installed on the `dev machine` so docker containers be run locally (future work). Note that BCM infrastructure components are spawned in separate dockerd instances than the one listed here (those nested within LXC system containers).
  2. [ZFS](https://en.wikipedia.org/wiki/ZFS) - Used for LXC system container storage backend. dockerd instances inside each LXC system container are redirected to distinct directory-based storage pools. Future BCM versions will work to software-define the dockerd storage backend using [CEPH](https://en.wikipedia.org/wiki/Ceph_(software)) where appropriate.
  3. [LXD/LXC](https://linuxcontainers.org/lxd/introduction/) - LXD is installed on the `dev machine` so you can deploy BCM scripts locally for testing and development. The `dev machine` is configured to NOT LISTEN on the network by default.
  4. [mulitpass](https://github.com/CanonicalLtd/multipass) - Multipass allows you to run QEMU/KVM-based virtual machines. Extremely useful for testing and development purposes. Visit the [BCM multipass directory](../multipass/) for additional details.
* Calls `./provision.sh` which initializes (via `lxd init`) the LXD configuration on your local `dev machine`. It configures LXD endpoint on `dev machine` to operate in [clustering mode](https://lxd.readthedocs.io/en/latest/clustering/) with a node count of one. You can simulate LXD clusters or more than one node by running LXD in [multipass VMs](../multipass/).


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

# docker info should show an operational node
docker info
```

You can inspect the `$BCM_RUNTIME_DIR/clusters/lxd_projects/` directory to view the files that were created. The `endpoints` and `lxd_projects` directories should exist. The LXD preseed file that was used to initialize the LXD daemon on the `dev machine` can be found at `$BCM_RUNTIME_DIR/clusters/lxd_projects/endpoints/local/lxd_preseed.yml`. This file contains sensitive password information and is thus git committed to $BCM_RUNTIME_DIR/.  `local` here refers to the LXD remote endpoint for your dev machine (local) which can be discovered by running `lxc remote list`.

To continue this tutorial, jump up and down to the [../lxd/](../lxd/) directory to start deploying BCM infrastructure components to your local `dev machine`. This is where you can deploy BCM data center components to any cluster-mode LXD endpoint. All the scripts in this directory are applied to your currently active LXC remote (`lxc remote get-default`).

## Next step: Trezor for Cryptographic Operations

To continue, delve into the [./mgmt_plane/](./mgmt_plane/) directory. This section shows how easy it is to get a fully functional Trezor T operating on your `dev machine`.