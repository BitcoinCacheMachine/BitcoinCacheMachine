# lxd/

What's in this directory? The entrypoint is ./up_lxd.sh. This script deploys Bitcoin Cache Stack to the ACTIVE LXD ENDPOINT. The endpoint can be selected using the LXD client/API. ./up_lxd.sh is executed automatically if multipass or cloud-init is being used. When deploying BCS on bare-metal, you will start with ./up_lxd.sh after sourcing your ./lxd.env file.

```bash
# show lxd remote endpoints
lxc remote list

# add a remote endpoint where 'remotehost' is the DNS or IP address of the host running a listening LXD daemon.
lxc remote add remotehost remotehost:8443 --accept-certificate

# configure your local lxd client to execute lxc commands against the remote LXD endpoint
lxc remote set-default remotehost
```

As always, modify ./lxd.env BEFORE executing ./up_lxd.sh to specify which components you want deployed.