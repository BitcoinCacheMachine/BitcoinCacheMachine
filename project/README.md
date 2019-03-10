# Project

This folder contains all the scripts required for deploying Bitcoin and Lightning-related software to your cluster.

All BCM data centers have a base workload containing criticial components such as a SOCKS5 TOR proxy, TOR-enabled DNS, Docker Registry Mirror and private registry, and a comprehensive [Kafka stack](https://kafka.apache.org/). Application-level containers like [bitcoind](https://github.com/bitcoin/bitcoin), [c-lightning](https://github.com/ElementsProject/lightning), (TODO) BTCPay, (TODO) web wallet interfaces, etc., are deployed using `bcm stack deploy` as discussed below. 

In general, the steps you take to deploy your own infrastructure is as follows:

1) Download BCM from github and run setup to configure your environment (done above).
2) Run `bcm init`, which ensures you have Trezor-backed GPG certificates at your management host (i.e., [SDN Controller](https://www.sdxcentral.com/sdn/definitions/sdn-controllers/)). Your BCM data center uses this certificate to encrypt backups of user data, among other things.
4) WORK IN PROGRESS:  Use `bcm stack deploy` to deploy supported software BCM cluster. When you deploy a component such as with `bcm stack deploy clightning`, clightning along with all its depedencies are provisioned to your active cluster (use `bcm info` and see `LXD_CLUSTER` or run `lxc remote get-default`). Essential BCM data center components that are common to ALL BCM deployments are also automatically provisioned. These services include TOR (SOCKS5 proxy, TOR-enabled DNS, & TOR Control), Docker Registry mirror and Private Registry (for docker image caching), and a Kafka logging stack which provides distributed event-driven messagaging for real-time streaming applications as well as some web interfaces that provide Kafka stack diagnostics ([topicsui](https://github.com/Landoop/kafka-topics-ui), schema-registry UI, Kafka-connect UI.

The commands above each have a reverse command, e.g., `bcm stack remove` (4), `bcm cluster destroy` (3), and `bcm reset` (2). Use `bcm info` to determine your active environment variables. `bcm show` provides an overview of your LXC containers, storage volumes, networks, images, remotes, etc..



## Planned Features


* Have BCM provide physical network underlay services: pre-configured [pi-hole](https://pi-hole.net/) to block DNS-level ad services. DHCP with name-autoregistration. A caching DNS server that uses TOR for outbound transport and consults `1.1.1.1` using a persistent TLS connection. This works ONLY when running BCM on a computer that has at LEAST TWO (2) physical network interfaces, one physically dedicated to network underlay services.
* Expose [wireguard](https://www.wireguard.com/) endpoint as ONLY ACTIVE service (per BCM project) using MACVLAN on the physical network underlay. This helps facilitate authentication, authorization, and end-to-end encryption of clients (e.g., laptops, desktops, mobile clients) connecting to any data center services from the local network (physical network underlay). In other words, to access services hosted by your BCM data center, you MUST FIRST VPN into the data center using a wireguard client. This piece will be implemented in a client-based docker container to intelligently route between local LAN wireguard and TOR-to-wireguard (when not on the local network).
* (WORK IN PROGRESS) The BCM SDN Controller intelligently deploys components across failure domains (i.e., individual x86_64) to achieve local high-availability.
* Planned application-level software includes [clightning](https://github.com/ElementsProject/lightning), [lnd](https://github.com/lightningnetwork/lnd) & [eclair](https://github.com/ACINQ/eclair) lightning daemons, [OpenTimestamps Server](https://github.com/opentimestamps/), various wallet interfaces and/or RPC interfaces (e.g., for desktop application integration), [esplora block explorer from Blockstream](https://github.com/Blockstream/esplora), [lightning-charge](https://github.com/ElementsProject/lightning-charge), etc.. 
* Individual services (e.g., bitcoind RPC, lnd gRPC, web-based wallet interfaces, etc.) can optionally be exposed as authenticated stealth onion services allowing your TOR-enabled smartphone to securly access various interfaces from the Internet.
