# Multipass and Bitcoin Cache Machine

[`multipass`](https://github.com/CanonicalLtd/multipass) is software (available as a [snap](https://snapcraft.io/)) that orchestrates the creation, management, and maintenance of QEMU/KVM VMs. Multipass is installed on the `admin machine` when running provisioning scripts found in `$BCM_LOCAL_GIT_REPO/admin_machine/` BCM scripts use the `multipass` CLI to create one or more hardware-enforced VMs. Each VM created by BCM multipass scripts runs a cloud-based Ubuntu 18.04 LTS image.

The scripts in this directory help you get started testing BCM quickly. Running `bash -c "./up_multipass_cluster.sh -c CLUS1 -m 3"` at the terminal will create a series of multipass VMs. Each VM will be named CLUS1-00, CLUS1-01, ...  The last parameter is the number of member nodes you want in your LXD cluster.  In the example, there will be 4 VMs total, one for the cluster master (assumed) and 3 additional member nodes. If you run `bash -c "./up_multipass_cluster.sh CLUS1"` (without the integer parameter), a single VM will be created. In all cases, `up_multipass_cluster.sh` leaves you with one or more Ubuntu VMs that are up-to-date and have necessary dependencies. Furthermore, LXD in each VM is [preseeded](https://lxd.readthedocs.io/en/latest/clustering/#preseed) and configured to operate in a cohesive cluster. 

Each VM represents available CPU, memory, disk, and networking that you can use to deploy BCM components.

# multipass Requirements

To run multipass, you must have a computer capable of running QEMU/KVM-based VMs which is typical with a developer or server machine. In some cases, you might have to visit your BIOS to ensure that hardware-based virtualization features are enabled. Low-end laptops typical of the home market may not have the necessary hardware requirements to run BCM in a multipass VM. However, you can always still run BCM on [bare-metal](./lxd/README.md)!  

To install `multipass` manually, run the following command. Also remember that `$BCM_LOCAL_GIT_REPO/admin_machine/setup.sh` installs `multipass` on the `admin machine` during provisioning as well.

```bash
sudo snap install lxd --candidate
```

# Script descriptions

Each section below reviews what each script does.

## Creation Scripts

### ./up_multipass_cluster.sh

This is what you're going to run when in the ./multipass directory. It has 2 parameters: `-c` for the cluster name, and `-m` for the number of additional nodes beyond 1 you want provisioned.  Pertinent examples, 

* `./up_multipass_cluster.sh -c HOME -m 2` -- This will provision a total of three multipass VMs each prepended with "HOME". The VMs will be "HOME-00", "HOME-01", and "HOME-02". This is the recommended command when testing on the `admin machine` since it provisions a cluster of machines (representing physical hosts) that allow a quorum to be reached. Of course, BCM works just as well when developing against a single-host cluster.
* `./up_multipass_cluster.sh -c HOME` -- This will provision one multipass VM named "HOME-00". HOME-00 will still be configured to operate in a LXD cluster even though it hasn't reached a quorum.

### ./stub.env.sh

This script creates the .env file needed for each LXD endpoint. . `./stub_env.sh` uses the `envsubst` command to substitute environment variables from the template files in the ./env/ directory. The resulting file gets stored in the `~/.bcm/clusters/$BCM_CLUSTER_NAME/endpoints/$BCM_MULTIPASS_VM_NAME`.

### ./multipass_vm_up.sh

This script actually creates the VM using the `multipass` cli.  The `multipass launch` command passes a [cloud-init](https://cloud-init.io/) file to the VM for provisioning directly after launch. The static `./cloud_init.yml` is used to initially provision ALL multipass hosts (master and members). The `cloud-init` file installs all necessary base OS dependencies such as ([ZFS](https://en.wikipedia.org/wiki/ZFS), `wait-for-it`, which is helpful to determine when service come online. (TODO `tor` is also installed for optionally exposing the LXD REST API over an authenticated onion service). The cloud-init definition also removes the default LXD client that comes with the Ubuntu base image and instead installs the latest candidate LXD via snap.

This script continues by obtaining the runtime IP address of the multipass VM then passing control over to either `./provision_lxd_master.sh` or `./provision_lxd_member.sh`, depending on whether the multipass VM is the first host in the cluster, i.e., the host ending in '-00'.

### provision_lxd_master.sh

This script starts by creating an LXD preseed file, storing it in `~/.bcm/clusters/$BCM_CLUSTER_NAME/endpoints/$BCM_MULTIPASS_VM_NAME/lxd/`. The resulting file is copied up to the multipass VM then the `lxd init` command is issued, passing in the preseed file. After LXD is configured, the resulting lxd.cert file in the daemon is copied back to the `admin_machine` for further provisioning activities. The lxd.cert is stored in the same directory as the LXD preseed file. 

`provision_lxd_master.sh` completes by adding an LXD remote to the `admin_machine` lxd client (via `lxd remote add`). Furthermore, the LXD client target is defaulted to first cluster member (i.e., "-00") via `lxd remote set-default`.

### provision_lxd_member.sh

`provision_lxd_member.sh` performs similar functions to `provision_lxd_master.sh` and is required because LXD preseed files for VMs joining an existing cluster is different from the first host in the cluster. All resulting preseed files are stored under `~/.bcm/clusters/$BCM_CLUSTER_NAME/endpoints/$BCM_MULTIPASS_VM_NAME/lxd/`.

## ./destroy_cluster.sh

This script iterates over the VMs that have the specified cluster name and deletes them. It also removes related files in `~/.bcm/clusters/$BCM_CLUSTER_NAME`.

## ./destroy_multipass.sh

This script is called by `./destroy_cluster.sh` and performs destruction processes scoped to a single VM/LXD endpoint.