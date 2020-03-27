

# bcm_host_template

This repo is shared by BCM `cachestack` and Bitcoin Cache Machine. `./up_lxc.sh` provisions a host template based on Ubuntu (Cosmic) and with the latest docker daemon.

## Storage

The ZFS file system is used for back LXD system containers. However, each /var/lib/docker directory in each system container is "bind-mounted" (using lxc ) and so exists outside of the ZFS storage pool. One could theoretically back the ZFS storage pool with multiple physical disks for a software-defined RAID-like experience.