
# host_template

the host_template/ directory contains files needed to get a dockerd baseline so we can deploy stateless docker containers.

## Storage

The ZFS is used for back each LXD system container. ZFS is an efficient copy-on-write file system, and BCM scripts utilize its features heavily. BCM scripts prepare LXC host for operation, then creates a ZFS snapshot so the preparation doesn't have to occur each time. The preparation phase can be remitted to the LXC system container update mechanism (TODO).

TheHowever, each /var/lib/docker directory in each system container is "bind-mounted" (using lxc ) and so exists outside of the ZFS storage pool. One could theoretically back the ZFS storage pool with multiple physical disks for a software-defined RAID-like experience.