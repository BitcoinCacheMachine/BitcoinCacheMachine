# BCM Clusters

A BCM Cluster is defined as a set (one or more) of machines that have been configured to operate in a [LXD Cluster](https://lxd.readthedocs.io/en/latest/clustering/). Endpoint operating in a BCM cluster are assumed to have private networking environment that is low latency and high bandwidth, such as a home or office LAN. By running a cluster of count three (3) or more, you can achieve local high availability (Local HA). However, you can still deploy BCM to a single machine including your SDN controller itself.

Unless you specify otherwise, the BCM CLI will automatically provision a single-endpoint cluster for you on your localhost. If your localhost (e.g., SDN Controller) supports hardware virtualization, [multipass](https://github.com/CanonicalLtd/multipass) will be installed locally and BCM data-center components will be deployed to that. If your hardware doesn't support virtualization, BCM will be installed to your localhost (bare-metal). This is better for performance, but compromises on security due to the lack of hardware virtualization.

Of course, you can always deploye BCM to one or more remote machines. The only assumption is that each machine is running Ubuntu 18.04 (Desktop or Server) and has SSH enabled on port 22. Each remote machine you provision MUST be DNS-resolvable by your SDN controller.

Clusters are created and destroyed using the `bcm cluster create` and `bcm cluster destroy` commands, respectively. Future versions of BCM will enable the capability to expose SSH endpoints via an authenticated TOR onion service. 

To facilitates bare-metal deployments to your SDN controller, `$BCM_GIT_DIR/setup.sh` configures your SDN controller to host `openssh-server` and its configured to listen locally at `hostname` (i.e., 127.0.1.1)).

# How to prepare a physical server for BCM workloads

If you want to run BCM on one or more dedicated server machines (e.g., an old NUC on your home network), you must first prepare it. It is recommended that you install a fresh copy of Ubuntu 18.04 Server on these machines using the instructions below. You will need Ubuntu Server 18.04 Server [installed on a USB thumb drive](https://tutorials.ubuntu.com/tutorial/tutorial-create-a-usb-stick-on-ubuntu#0). Ensure the drive is plugged into the computer before powering it on. Also ensure the computer is plugged into the network.

1. Boot to the USB medium. You may have to press F11 at boot to ensure the device boots from the USB thumb drive. When the boot menu appears, choose "EUFI Mass Storage Device 1.0".
2. Press enter to accept the defaults regarding keyboard layout (US English).
3. Press Enter to select the default option of "Install Ubuntu"
4. Ensure your network interface gets an IP address from the network. Press Done to proceed.
5. Leave the proxy address field EMPTY and click Done to continue.
6. Leave the Mirror address at its default, then press Enter (Done) to continue.
7. On the "Filesystem setup" menu, choose "Use Entire Disk" and press ENTER.
8. On the "Choose the disk to install to:" menu, ensure the first disk is selected, then press Enter.
9. Under "Used Devices", use the arrow key to highlight 'partition 2' then press Enter. Go to Edit -> Enter. Change the Format to say 'btrfs' and select 'Save' by pressing enter.  The / filesystem should be 'formatted as btrfs, mounted at /'.
10. Select "Done" on the "Filesystem setup" menu.  Choose "Continue" on the 'Confirm destructive action' screen. This results in the disk being erased and partitioned.
11. On the "Software selection" page, choose "Done" (don't select any packages) and select Done to continue.
12. On the User information page, enter the following details. For server name, choose a memorable name.

```
Name:           ubuntu
server name:    some_local_dns_name
Username:       ubuntu
password:       CHANGE_ME
password:       CHANGE_ME
```

13. Select 'Yes' to the 'Are you sure you want to continue' page.
14. Remove the installation media when directed and press enter to restart.

The server should start Ubuntu Server. If successful, you will be presented with a login prompt. Login with the username and password that was set up in previous steps, then run the following command:

---- TODO perform curl over TOR.
```bash
curl -sSL https://raw.githubusercontent.com/BitcoinCacheMachine/BitcoinCacheMachine/master/cluster/server_prep.sh | sudo bash
```

The output of the above command SHOULD end with 'SSH ONION SITE & AUTH TOKEN'. The value presented here should be securely transmitted to your administrator. The password that was set by the remote installation technician should be communicated as well.

Finish the process by restarting the computer:

```bash
sudo shutdown -r now
```

TODO: see if we can support boot-to-network (PXE) and cloud-init provisioning.