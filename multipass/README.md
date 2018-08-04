# Run BCM in a VM using multipass

`multipass` is software (available as a snap) that orchestrates the creation, management, and maintenance of virtual machines and associated Ubuntu images to simplify development. It creates QEMU/KVM-based VMs on a capable computer. Each virtual machine created by multipass for BCM runs a cloud-based Ubuntu 18.04 image. To run multipass, you must have a computer capable of running QEMU/KVM-based VMs which is typical with a developer or server machine. Low-end laptops typical of the home market may not have the necessary hardware requirements to run BCM in a VM. But worry not, you can still run BCM on [bare-metal](./lxd/README.md).

The files present in this folder (./) are responsible for creating and destroying multipass-based cloud instances for BCM deployment. The scripts are executed against the multipass daemon on the same machine that's executing the script (maybe one day we can use a multipass remote API for VM creation). Multipass creates the VM and provides it with the ./multipass_cloud-init.yml file. The ./multipass_cloud-init.yml file instructs cloud-init process in the VM to prepare the OS for BCM. Cloud-init installs the necessary dependencies including ([ZFS](https://en.wikipedia.org/wiki/ZFS) for a LXD container storage container back-end, wait-for-it which is helpful to determine when service come online, and tor, for IP anonymity for outbound client/server queries. The cloud-init process then initializes the LXD daemon to accept incoming connections on the IP address that was assigned to the VM by the the multipass DHCP process. This makes the VM and its resources available to the `admin machine` via the LXD remote API. Again, Bitcoin Cache Machine deployed to ANY compatible LXD endpoint.

You can run Bitcoin Cache Machine (and standalone Cache Stack) within multipass VMs. However, `cachestack` is meant to provide underlay networking services for your LAN; running in a standalone `cachestack` in a VM only makes sense if you are able to provide the VM direct access to the underlay network. You can install `cachestack` on bare-metal, but you must instruct the deployment script which physical interface to attach to. A local `cachestack` is automatically deployed with every Bitcoin Cache Machine installation.

## Step 1: Prepare your system

To install multipass on a Debian based-OS capable of QEMU/KVM-based VMs, run the following command:

```bash
sudo snap install multipass --beta --classic
```

## Step 2: Update VM Hardware Specs by updating ~/.bcm/endpoints/{VM_NAME}.env

Let's assume you want to deploy BCM in a standalone multipass VM called `bcm-01`. Create a file at ~/.bcm/endpoints/bcm-01.env. Next, edit the file to define your BCM deployment. You MUST set BCM environment variables that start with "MULTIPASS_" for multipass VMs. You may set other BCM-related variables in the same file. The [default BCM environment variables](../resources/defaults.env) for more details on possible BCM deployment options.

## Choose which software-defined features you want deployed to your network

    Modify the relevant .env (`multipass_cloud-init.yml` if using multipass, `lxc.env` if running on bare-metal) file to specify which software-defined features to deploy. The values specified here guide the initial BCM installation script `lxc_up.sh`. More info can be found in ./docs/env.md

    After multipass is installed and you have updated and saved the .env file, you can start BCM deployment/installation (BASH) script:

    ```bash
    ./multipass_up.sh
    ```

Your console will show the progress of the BCM deployment. After completion, a QR code and TOR .onion address should appear which will allow you to administer your BCM.
