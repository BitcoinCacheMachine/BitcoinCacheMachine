# Multipass and Bitcoin Cache Machine

`multipass` is software (available as a snap) that orchestrates the creation, management, and maintenance of virtual machines (VMs) and associated Ubuntu images to simplify development. Each VM created by BCM multipass scripts run a cloud-based Ubuntu 18.04 image. 

To run multipass, you must have a computer capable of running QEMU/KVM-based VMs which is typical with a developer or server machine. In some cases, you might have to visit your BIOS to ensure that hardware-based virtualization features are enabled. Low-end laptops typical of the home market may not have the necessary hardware requirements to run BCM in a multipass VM. However, you can always still run BCM on [bare-metal](./lxd/README.md)!  

The files present in this folder are responsible for creating and destroying multipass-based cloud instances for BCM deployment. The scripts are executed against the multipass daemon on the same machine that's executing the script.

Upon launch, multipass provides the VM with a unique ./multipass_cloud-init.yml file. This file instructs the cloud-init process in the VM to prepare the underlying OS for BCM components. Cloud-init installs the necessary dependencies including ([ZFS](https://en.wikipedia.org/wiki/ZFS) for a lxc container storage container back-end, `wait-for-it` which is helpful to determine when service comes online, and `tor` for (eventually) exposing SSH and and LXD remote API endpoints over authenticated TOR onion sites. By default the cloud-init process initializes the LXD daemon to accept incoming connections on its one (1) external interface. By the end of the multipass creation phase, you should have a remotely accessible LXD endpoint ready to receive BCM commands.

## How to run BCM in a multipass VM

You can run BCM in a multipass VM by running the `./up_multipass.sh` script. Before executing the script, you MUST source your BCM multipass environment variables. An example is shown in ./bcm01.env which is a great way to get started with BCM.

`up_multipass.sh` does the following things:

1. Makes sure your computer has `multipass` available. If not, it attempts to install multipass via SNAP.
2. Creates and manages files in ~/.bcm/endpoints/ and ~/.bcm/runtime/
3. Creates new BCM_LXD_SECRET for the multipass VM ans stores it in ~/.bcm/$BCM_MULTIPASS_VM_NAME as specified in your sourced environment.
4. Creates a modified `./multipass_cloud-init.yml` file to initialize the new VM.
5. Launches the new VM with a base OS of Ubuntu 18.04.
6. Provisions BCM components via LXD as specified by the current environment variables.
7. Performs a git commit to ~/.bcm for version control of sensitive information.

The example `./bcm01.env` file creates a new VM named *bcm-01* and provides it with *30G* of disk space, *4G* of memory, and *4* vCPUs. It also directs BCM scripts to provision BCM components to the new multipass VM via the LXD API.

```bash
#!/bin/bash

export BCM_MULTIPASS_VM_NAME="bcm-01"
export BCM_MULTIPASS_DISK_SIZE="30G"
export BCM_MULTIPASS_MEM_SIZE="4G"
export BCM_MULTIPASS_CPU_COUNT="4"
export BCM_MULTIPASS_PROVISION_LXD="true"
```

If you want to create more than one multipass VM, create a file at `~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env` which specifies BCM multipass and BCM-proper deployment options for the endpoint.