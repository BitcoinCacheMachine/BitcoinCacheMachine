# IMPORTANT NOTE

This section is still under construction.  Your attempts at running scripts here will likely fail at the moment. Once we get a stable product with a semi-complete feature set, we will merge changes into the master branch. Feel free to inspect the codebase to see what we're working on!

# Deploying Bitcoin Cache Machine components using the LXD API

This is where BCM data center components reside. The main entrypoint at this level is `./up_lxc_project.sh`. This script calls subscripts to provision the data center. BCM Environment variables, which are refreshed (i.e., exported) every time any script executes, guide the logic the installation and deployment process. All `up_lxc_*.sh` scripts are designed to be idempotent; running the scripts multiple times SHOULD NOT change the resulting data center deployment. 

## Assumptions

The instructions in this directory make the following assumptions:

1. you have one or more LXD remote endpoints defined on the `dev machine`. You can run `lxc remote list`, or `lxc remote get-default` to view the current LXD endpoints you have defined on your `dev machine`. The endpoint could be local, in which case BCM will be deployed to the LXD daemon running on the `dev machine` (developer machine). It could be the result of ../up_multipass.sh, which creates a new multipass-based VM with a remote LXD daemon, or it could be a home server that you've [manually provisioned](../../docs/installation/lxd_host_prep.md)
2. All scripts with `lxc` in the name ASSUMES that the commands are being executed against to THE CURRENT LXD remote endpoint. Issue the `lxc remote get-default` command to determine your active endpoint.
3. BCM LXD scripts SHOULD be loaded PRIOR to executing any `lxd` scripts. [These environment variables define BCM-specific deployment options](../resources/README.md). The files in ../resources/ MUST be copied to the ~/.bcm/defaults/ directory unless you want to fork Bitcoin Cache Machine. When executed, `../../setup.sh` at the root of this repository creates the necessary files and directories (including ~/.bcm) to create BCM instances in idiomatic manner. All endpoint-specific information is kept in ~/.bcm on the `admin machine`. Thus, you should back it up and protect it accordingly. Future versions of BCM will integrate Trezor-T on-board storage for management of this sensitive information (including key and password management).






Decide where you want to run your BCM workload. You can deploy BCM to the `dev machine` for quick and convenient testing. You can consider running BCM in a [multipass-based VM](./multipass/) or in a [cloud provider via cloud-init](./cloud_providers/). `multipass` VMs use lower-level hardware-based virtualization which provide additional security guarantees. In the end, all you need to run BCM component is a LXD endpoint configured and controllable by your `dev machine`. Use the `lxc remote list`, `lxc remote get-default` and related commands.



## Privilege Levels

Unfortuantely, BCM is currently built entirely on privileged LXC containers. This is because Docker swarm could not be made functional using unprivileged containers. There are several mitigating factors that reduce the overall risk involved with this limitation:

* `dockerd` runs within each privileged LXC container, hus `dockerd`-level process isolation is in effect for running application-level containers.
* The network-level attack surface of BCM is extremely small. By default BCM exposes ZERO services to the local network interfaces EXCEPT for the LXD endpoint (for the management plane). Any service exposed to the internet is exposed as an authenticated onion whenever possible. This provides cloud-like connectivity to your BCM instance in your home or office. You get end-to-end encryption and IP anonymity as well as Layer 4 authentication.

### priviliged.yml


### unprivileged.yml

