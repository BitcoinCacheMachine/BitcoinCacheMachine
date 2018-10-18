# Multipass and Bitcoin Cache Machine

[`multipass`](https://github.com/CanonicalLtd/multipass) is software (available as a [snap](https://snapcraft.io/)) that orchestrates the creation, management, and maintenance of QEMU/KVM VMs. BCM scripts use the multipass command line tool to create VMs locally (usually run on the `admin machine` for testing). Each VM created by BCM multipass scripts runs a cloud-based Ubuntu 18.04 LTS image.

The scripts in this directory help you get started testing BCM quickly. Running `bash -c "./up_lxd_cluster.sh CLUS1 3"` at the terminal will create a series of multipass VMs. Each VM will be named CLUS1-00, CLUS1-01, ...  The last parameter is the number of member nodes you want in your LXD cluster.  In the example, there will be 4 VMs total, one for the cluster master (assumed) and 3 additional member nodes. If you run `bash -c "./up_lxd_cluster.sh CLUS1"` (without the integer parameter), a single VM will be created. In all cases, `up_lxd_cluster.sh` provides you with one or more generic Ubuntu VMs configured as an LXD cluster. Each VM represents available CPU, memory, disk, and networking that you can use to deploy BCM components.

# multipass Requirements

To run multipass, you must have a computer capable of running QEMU/KVM-based VMs which is typical with a developer or server machine. In some cases, you might have to visit your BIOS to ensure that hardware-based virtualization features are enabled. Low-end laptops typical of the home market may not have the necessary hardware requirements to run BCM in a multipass VM. However, you can always still run BCM on [bare-metal](./lxd/README.md)!  

# Script descriptions

Each section below reviews what each script does.

## Creation Scripts

### ./up_lxd_cluster.sh

This is the entrypoint into the ./multipass directory. 

### ./stub.env.sh

### ./multipass_vm_up.sh

This script actually creates the VM using the `multipass` client tool.  The `multipass launch` command passes a `cloud-init` file to the VM for provisioning directly after launch. The `cloud-init` file that is used to provision ALL multipass hosts is ./cloud_init.yml. The `cloud-init` filee installs all necessary Base OS dependencies such as ([ZFS](https://en.wikipedia.org/wiki/ZFS), `wait-for-it` which is helpful to determine when service comes online, and tor. It also removes the default LXD client and installs the latest candidate LXD snap package.

This script continues by obtaining the runtime IP address of the multipass VM then passing control over to either `./provision_lxd_master.sh` or `./provision_lxd_member.sh`, depending on whether the IS_MASTER parameter.

### provision_lxd_master.sh

### provision_lxd_member.sh



## ./destroy_cluster.sh

## ./destroy_multipass.sh