# Deploying Bitcoin Cache Machine via the LXD API

The instructions in this directory make the following assumptions: 

1) you have one or more LXD remote endpoints defined on the `admin machine`. You can run `lxc remote list`, or `lxc remote get-default` to view the current LXD endpoints you have defined on your `admin machine`. The endpoint could be local, in which case BCM will be deployed to the LXD daemon running on the `admin machine` (developer machine). It could be the result of ../up_multipass.sh, which creates a new multipass-based VM with a remote LXD daemon, or it could be a home server that you've [manually provisioned](../../docs/installation/lxd_host_prep.md)

2) All scripts with `lxd` in the name ASSUMES that the commands are being executed against to THE CURRENT LXD remote endpoint. Issue the `lxc remote get-default` command to determine your endpoint.

3) BCM LXD scripts SHOULD be loaded PRIOR to executing any `lxd` scripts. [These environment variables define BCM-specific deployment options](../resources/README.md). The files in ../resources/ MUST be copied to the ~/.bcm/defaults/ directory unless you want to fork Bitcoin Cache Machine. When executed, `../../setup.sh` at the root of this repository creates the necessary files and directories (including ~/.bcm) to create BCM instances in idiomatic manner. All endpoint-specific information is kept in ~/.bcm on the admin machine. Thus, you should back it up and protect it accordingly. Future versions of BCM will integrate Trezor-T on-board storage for management of this sensitive information (including key and password management).
