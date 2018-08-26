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




The `underlay` LXC container requires at least two (2) physical network interfaces. The first interface is the `untrusted outside`. `underlay` uses MACVLAN to obtain a DHCP address on the upstream DHCP server such as your DSL or cable modem, or the DHCP server running on your existing internal network.

The second interface represents the `trusted inside`. This interface is entirely used by the LXC container via a physical attachment. 

The `untrusted outside` and `trusted inside` interfaces MUST be explicitly set by the administrator (see ./resources/defaults/underlay.env). DHCP and DNS is served to clients on the trusted inside interface. `underlay` can also be configured to forward arbitrary traffic out the untrusted interface. The outside interface obtains IP and routing information from a DHCP server upstream, such as a DSL or cable modem. The untrusted outside interface firewall policy disallows all incoming connections. The DNS server on exposed on the inside interface is configured to use TOR for outbound external queries and cache known entries for local LAN clients. DHCP clients requesting an address SHOULD provide a hostname which is auto-pushed into the DNS. A properly working `underlay` makes BCM deployments far easier and consistent because we know addressing and DNS are correctly configured!