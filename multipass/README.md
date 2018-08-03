# Run BCM in a VM using multipass

`multipass` is software (available as a snap) that orchestrates the creation, management, and maintenance of virtual machines and associated Ubuntu images to simplify development. It creates QEMU/KVM-based VMs on a capable computer. Each virtual machine created by multipass for BCM runs a cloud-based Ubuntu 18.04 image. To run multipass, you must have a computer capable of running QEMU/KVM-based VMs which is typical with a developer or server machine. Low-end laptops typical of the home market may not have the necessary hardware requirements to run BCM in a VM. But worry not, you can still run BCM on bare-metal!

The files present in this folder (.e., ./multipass) are responsible for creating and destroying multipass-based cloud instances. The scripts are executed against the multipass daemon on the same machine (i.e., no multipass remote API that I know of). Multipass creates the VM and passes control to cloud-init within the VM.  The ./multipass_cloud-init.yml file instructs cloud-init to install the necessary dependencies (ZFS, wait-for-it), and initializes the LXD daemon to accept incoming connections on the IP address that was assigned to the VM by the the multipass DHCP process.

You can run Bitcoin Cache Machine and Bitcoin Cache Stack within multipass VMs. However, since Bitcoin Cache Stack is meant to provide underlay networking services for your LAN, running Bitcoin Cache Stack only makes sense if you are able to provide the VM direct access to the underlay. Running Bitcoin Cache Stack in a VM is useful when running Bitcoin Cache Machine on the same machine (and "virtual" LAN segment, such as in a development settings.

## Step 1: Prepare your system

    To install multipass on a Debian based-OS capable of QEMU/KVM-based VMs, run the following command:

    ```bash
    sudo snap install multipass --beta --classic
    ```

## Step 2: Update VM Hardware Specs by updating ~/.bcs/multipass.env

    Next, modify `~/.bcs/multipass.env` to define the amount of RAM, CPUs, and disk that is given to the VM. Save the file and load the environment variables by typing `source multipass.env`. A minimum of 2 CPUs is recommended, as well as 2048 MB of memory. 20 GB of disk space is recommended for testnet operation.

3. Choose which software-defined features you want deployed to your network

    Modify the relevant .env (`multipass_cloud-init.yml` if using multipass, `lxc.env` if running on bare-metal) file to specify which software-defined features to deploy. The values specified here guide the initial BCM installation script `lxc_up.sh`. More info can be found in ./docs/env.md

    After multipass is installed and you have updated and saved the .env file, you can start BCM deployment/installation (BASH) script:

    ```bash
    ./multipass_up.sh
    ```

Your console will show the progress of the BCM deployment. After completion, a QR code and TOR .onion address should appear which will allow you to administer your BCM.
