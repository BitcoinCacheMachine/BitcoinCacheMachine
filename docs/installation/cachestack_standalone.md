
# Cache Stack for Bitcoin Cache Machine

The Cache Stack is a software-defined network that provides underlay networking and caching services for your LAN or routed network and is designed to work closely with [Bitcoin Cache Machine](https://github.com/farscapian/bitcoincachemachine). This helps keep traffic off your Internet connection, which is good for privacy and performance. Other services such as PXE boot for automated provisioning are possible. Cache Stack is meant to be deployed on a reliable always-on x86_x64 computer. Cache Stack is PLANNED to be deployable to three independent commodity x86_x64 for local high availability (this can be achieved with LXD clustering and VXLAN). Bitcoin Cache Stack is installed entirely via the LXD API.

The Cache Stack can be deployed with the following services:

* (planned) - DHCP and DNS with hostname auto-registration.
* (planned) - A DNS cache configured to use TOR for outbound queries. Local BCS instances consult the local DNS cache for hostname resolution.
* (implemented) - An untrusted bitcoind instance in archival mode and accepting P2P connections on the internal/trusted underlay network.
* (implemented) - An IPFS daemon for serving cached static content (planned).
* (implemented) - An HTTP/HTTPS proxy based on [squid]("http://www.squid-cache.org/") for HTTP and HTTPS requests originating from daemons operating in a BCS instance.
* (implemented) - One or more docker registry mirrors each configured as a pull-through cache.
* (implemented) - A private docker registry for those interested in controlling the build process.

In addition, the LXD daemon on the host running the Cache Stack is configured to prepare and serve LXC images with docker-ce installed to trusted clients on the LAN. All services are PLANNED be configured to use TOR for outbound queries (for cache misses) where appropriate. 

## How to Run Bitcoin Cache Stack

If you can run modern Ubuntu 18.04, you can run BCS. Cache Stack is exclusively deployed via the LXD API. This means you can "install locally" through a unix socket, or you can deploy BCS to a remote machine on the network through a TLS connection. See ./docs/installation/remote_lxd.md for more details.

Please remember that BCS is for testing purposes only and is under heavy development. REPEAT!!!! BCS SHOULD BE CONSIDERED FOR TESTING PURPOSES ONLY!

You can run BCS as a QEMU/KVM-based VM (see ./docs/installation/multipass.md) or on bare-metal (see ./docs/baremetal.md) running Ubuntu 18.04.  It doesn't really make any sense to run BCS "in the cloud" since its purpose is to provide underlay network services for home and small office settings.

