
# BCMNET

This folder hosts all applications that need to connect to the underlay network. In general, lxc hosts that have connectivity to the bcmnet network can access the following services hosted on lxc host `gateway` located at 192.168.4.1:

* Docker Registry Mirror accessible via 'bcmnet:5000' via TLS 1.3 with certificate-based client-server authentication.
* Docker Private Registry accessible via 'bcmnet:443' via TLS 1.3 with certificate-based client-server authentication.





<!-- 
# `cachestack` for Bitcoin Cache Machine

The `cachestack` is a software-defined network that provides underlay networking and caching services for your LAN or routed network and is designed to work closely with [Bitcoin Cache Machine](https://github.com/farscapian/bitcoincachemachine). This helps keep traffic off your Internet connection, which is good for privacy and performance. Other services such as PXE boot for automated provisioning are possible. `cachestack` is meant to be deployed on a reliable always-on x86_x64 computer. `cachestack` is PLANNED to be deployable to three independent commodity x86_x64 for local high availability (this can be achieved with LXD clustering and VXLAN). Bitcoin `cachestack` is installed entirely via the LXD API.

The `cachestack` can be deployed with the following services:

* (implemented) - An untrusted bitcoind instance in archival mode and accepting P2P connections on the internal/trusted underlay network.
* (implemented) - An IPFS daemon for serving cached static content (planned).
* (implemented) - An HTTP/HTTPS proxy based on [squid]("http://www.squid-cache.org/") for HTTP and HTTPS requests originating from daemons operating in a BCS instance.
* (implemented) - One or more docker registry mirrors each configured as a pull-through cache.
* (implemented) - A private docker registry for those interested in controlling the build process.

In addition, the LXD daemon on the host running the `cachestack` is configured to prepare and serve LXC images with docker-ce installed to trusted clients on the LAN. All services are PLANNED be configured to use TOR for outbound queries (for cache misses) where appropriate. 

## How to Run Bitcoin `cachestack`

If you can run modern Ubuntu 18.04, you can run BCS. `cachestack` is exclusively deployed via the LXD API. This means you can "install locally" through a unix socket, or you can deploy BCS to a remote machine on the network through a TLS connection. See ./docs/installation/remote_lxd.md for more details.

Please remember that BCS is for testing purposes only and is under heavy development. REPEAT!!!! BCS SHOULD BE CONSIDERED FOR TESTING PURPOSES ONLY!

You can run BCS as a QEMU/KVM-based VM (see ./docs/installation/multipass.md) or on bare-metal (see ./docs/baremetal.md) running Ubuntu 18.04.  It doesn't really make any sense to run BCS "in the cloud" since its purpose is to provide underlay network services for home and small office settings.

# `cachestack` for Bitcoin Cache Machine

The `cachestack` is a software-defined network that provides underlay networking and caching services for your LAN or routed network and is designed to work closely with Bitcoin Cache Machine. This helps keep traffic off your Internet connection, which is good for privacy and performance. Other services such as PXE boot for automated provisioning are possible. `cachestack` is meant to be deployed on a reliable always-on x86_x64 computer. `cachestack` is PLANNED to be deployable to three independent commodity x86_x64 for local high availability. Bitcoin `cachestack` is installed entirely via the LXD API.

The `cachestack` can be deployed with the following services:
1) [required when in standalone mode] prepares and serves trusted LXD images to LXD clients,
2) [required] hosts one or more Docker Registry mirrors configured as [a pull-through cache](https://docs.docker.com/registry/recipes/mirror/)
3) [required] hosts a [private registry](https://docs.docker.com/registry/deploying/) for Docker images built during the BCM deployment process
4) [required] provides HTTP/HTTPS proxy/cache based on [Squid](http://www.squid-cache.org/)
5) [optional] IPFS node for 1) serving cached data to IPFS nodes on the LAN and 2) and pinning static content to /ipfs
6) [optional] TOR SOCKS5 proxy for BCM components making outbound client-server requests on the Internet
6) [optional] RSYNCD server to serve bulk data to LAN clients, such as pre-indexed Bitcoin blockchain data (useful for development). BCM components MAY use a remote cachestack/rsyncd instance for real-time file-system backups.
5) [optional] Bitcoin border node / archival node serving and downloading block over TOR. This can be useful during development; you can have an archival node serve blocks to more trusted full nodes.



In addition, the LXD daemon on the host running the `cachestack` is configured to prepare and serve LXC images with docker-ce installed to trusted clients on the LAN. All services are PLANNED be configured to use TOR for outbound queries (for cache misses) where appropriate. 

## How to Run Bitcoin `cachestack`

If you can run modern Ubuntu 18.04, you can run BCS. `cachestack` is exclusively deployed via the LXD API. This means you can "install locally" through a unix socket, or you can deploy BCS to a remote machine on the network through a TLS connection. See ./docs/installation/remote_lxd.md for more details.

Please remember that BCS is for testing purposes only and is under heavy development. REPEAT!!!! BCS SHOULD BE CONSIDERED FOR TESTING PURPOSES ONLY!

You can run BCS as a QEMU/KVM-based VM (see ./docs/installation/multipass.md) or on bare-metal (see ./docs/baremetal.md) running Ubuntu 18.04.  It doesn't really make any sense to run BCS "in the cloud" since its purpose is to provide underlay network services for home and small office settings.
 -->