# How Bitcoin Cache Machine uses Trezor

BCM Clusters are nothing more than sets of machines that have been configured to operate in a LXD Cluster. By running a cluster of count 3 or more, you can achieve high availability. However, you can still deploy BCM to a single machine (or two).  You can even deploy a BCM cluster to the same computer as your SDN controller, which is great when all you have is your desktop computer.

# How to prepare a physical server for BCM workloads

First, have Ubuntu Server 18.04 Server [installed on a USB thumb drive](https://tutorials.ubuntu.com/tutorial/tutorial-create-a-usb-stick-on-ubuntu#0). Ensure the drive is plugged into the computer before powering it on. Also ensure the computer is plugged into the network. For Antsle's, plug your CAT6 cable into the LOWER_LEFT ethernet receptical.

1. Boot to the USB medium. You may have to press F11 at boot to ensure the device boots from the USB thumb drive. When the boot menu appears, choose "EUFI Mass Storage Device 1.0".
2. Press enter to accept the defaults regarding keyboard layout (US English).
3. Press Enter to select the default option of "Install Ubuntu"
4. Ensure interface 'enp0s20f0' has an IP address from the network. Press Done to proceed.
5. Leave the proxy address field EMPTY and click Done to continue.
6. Leave the Mirror address at its default, then press Enter (Done) to continue.
7. On the "Filesystem setup" menu, choose "Use Entire Disk" and press ENTER.
8. On the "Choose the disk to install to:" menu, ensure the first disk is selected, then press Enter.
9. Under "Used Devices", use the arrow key to highlight 'partition 2' then press Enter. Go to Edit -> Enter. Change the Format to say 'btrfs' and select 'Save' by pressing enter.  The / filesystem should be 'formatted as btrfs, mounted at /'.
10. Select "Done" on the "Filesystem setup" menu.  Choose "Continue" on the 'Confirm destructive action' screen. This results in the disk being erased and partitioned.
11. On the "Software selection" page, choose "Done" (don't select any packages) and select Done to continue.
12. On the User information page, enter the following details. For server name, choose a memorable name.

    Name:           ubuntu
    server name:    some_local_dns_name
    Username:       ubuntu
    password:       CHANGE_ME
    password:       CHANGE_ME

13. Select 'Yes' to the 'Are you sure you want to continue' page.
14. Remove the installation media when directed and press enter to restart.

The server should start Ubuntu Server. If successful, you will be presented with a login prompt. Login with the username and password that was set up in previous steps, then run the following command:

```bash
curl -sSL https://raw.githubusercontent.com/BitcoinCacheMachine/ServerPrep/master/prep.sh | sudo bash
```

The output of the above command SHOULD end with 'SSH ONION SITE & AUTH TOKEN'. The value presented here should be securely transmitted to your administrator (e.g., Signal Private Messenger, Keybase Chat).

TODO: see if we can support boot-to-network (PXE) and cloud-init provisioning.