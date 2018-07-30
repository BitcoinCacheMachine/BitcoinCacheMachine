
# Bitcoin Cache Machine

> **IMPORTANT!!!!**
> BCM is intended for evaluation purposes ONLY!
> It is very new and under heavy development by a single
> author and HAS NOT undergone a formal security evaluation!
> USE AT YOUR OWN RISK!!!

Bitcoin Cache Machine (BCM) is an event-driven, software-defined data center created for developers, individuals, and small businesses wanting to own and operate their own bitcoin-related payment infrastructure. It's a Personal Financial Operating System (PFOS) based entirely on the ONLY secure blockchain--Bitcoin (as determined by the fabulous open-source implementation we call Bitcoin Core)! It's a platform for your Bitcoin-based business.

BCM deploys in a fully automated way and runs on bare-metal Ubuntu 18.04, in a VM, on-premise (preferred), or in the cloud (i.e., on someone elses computer!). It's consists entirely of open-source software. BCM is MIT licensed, so fork away and feel free to submit pull requests with your awesome ideas for improvement!

## Why Bitcoin Cache Machine Exists

If you're involved with Bitcoin, you will undoubtedly understand the importance of running your own fully-validating bitcoin node and operating your own IT infrastructure. Running a fully-validating node is easy enough--just download the software and run it on your home machine, but is that really enough to preserve your overall privacy? Did you configure it correctly? Are you also running a properly configured block explorer? Is your wallet software configured to consult your trusted full node? Has TOR for these services been tested properly? Are you routing your DNS queries over TOR?

There are tons of other areas where your privacy can be compromised if you're not careful. BCM is meant to handle these concerns by creating a privacy-centric software-defined automation network.

Bitcoin Cache Machine dramatically lowers the barriers to deploying and operating your own privacy-centric bitcoin payment infrastructure. If you can provide the necessary hardware (CPU, memory, disk), a LAN segment, and an internet gateway, BCM can do much of the rest. You can improve overall performance and enable more rapid development by installing a standalone `cachestack` component on your network! `cachestack` is especially useful when developing new line of business application on top of Bitcoin Cache Machine!

## Goals of Bitcoin Cache Machine

Below you will find some of the development goals for BCM.

* Provide a self-contained, event-driven, software-defined IT infrastructure for potential Bitcoin and Lightning-related applications.
* Be able to run entirely on commodity x86_x64 hardware for home and small office settings. You can run BCM on an old computer!
* Integrate exclusively free and open source software!
* Create a composable framework for deploying Bitcoin and Lightning-related components, databases, visualizations, web-interfaces, etc..
* Automate the deployment and operation (e.g., backups, updates, vulnerability assessments, key and password management, etc.) of each BCM deployment.
* Embrace hardware wallets for cryptographic operations where possible (e.g., Trezor-generated SSH keys or PGP certificates for authentication and encryption).
* Pre-configure all software to protect user's privacy (e.g., TOR for communication, disk encryption, minimal attack surface, etc.).
* Embrace decentralization and sovereignty of the individual (i.e., [Anarchy](https://en.wikipedia.org/wiki/Anarchy)).
* Pursue [Global Consensus and Local Consensus Models](https://twitter.com/SarahJamieLewis/status/1016832509709914112) for core platform components.

The trusted root of each BCM deployment from a [global consensus perspective](https://fieldnotes.resistant.tech/dags-and-decentralization/) is Bitcoin, the most secure and accomplished blockchain.

## How to Run BCM

If you can run a modern Linux kernel and [LXD](https://linuxcontainers.org/lxd/), you can run BCM. You can run BCM in a hardware-based VM (see ./docs/installation/multipass.md), directly on bare-metal (see ./docs/baremetal.md), or on someone elses computer (discouraged, but if you must) (see ./docs/installation/inthecloud_aws.md for an example). Bitcoin Cache Machine is deployed exclusively over the [LXD REST API](https://github.com/lxc/lxd/blob/master/doc/rest-api.md), so you can deploy BCM to any LXD-capable endpoint! LXD is widely available on various free and open-source linux platforms. BCM has been developed and primarily tested using Ubuntu 18.04.

`REPEAT!!!! BCM SHOULD BE CONSIDERED FOR TESTING PURPOSES ONLY!`

BCM is designed to be composable. For the most part, you can pick and choose your various infrastructure components to run for your required use case. This makes Bitcoin Cache Machine a great choice when developing a new bitcoin-related business idea!

BCM is meant for home and small office use which aligns with the spirit of decentralization.

## BCM Components

Bitcoin Cache Machine is where your bitcoin-related workloads reside. BCM instances are meant to be horizontally scalable by adding commodity hardware.

Each BCM is composed of the following:

* `cachestack` - a set of LXD components (networks, storage pool, profiles, etc.) and LXD containers that provide caching and underlay network services for Bitcoin Cache Machine components. You can install `cachestack` in standalone mode to provide network and caching services to your LAN components. If there is no CacheStack on your LAN segment, Bitcoin Cache Machine installs a local copy and uses it internally. Cache Stack serves LXD images to your local network (when in standalone mode), hosts one or more Docker Registries configured as a pull-through cache, and provides HTTP/HTTPS proxy services. Other services such as a Bitcoin archival node can be deployed to `cachestack`. This can be useful during development; you can have an archival node serve blocks to more trusted full nodes. More information about the Cache Stack and its components can be found in ./docs/architecture/cache_stack.md. Future versions of cachestack will include DHCP with hostname autoregistration and a DNS cache configured to use TOR.

* `manager1` [required], `manager2` [optional], `manager3` [optional] -- There are manager LXD hosts to to facilitate the Docker Swarm manager role for the rest of the swarm. The docker daemon on each manager host is configured to use `cachestack` as the Docker registry mirror. A Kafka messaging stack is deployed to each manager node for distributed messaging and is the system-of-record for user data. Manager LXC containers MAY be deployed to independent x86_x64 hardware for local high-availability using LXD clustering.  (PLANNED) `manager1` is deployed with an administrative web interface exposed over a TOR hidden service. Administrative interfaces (e.g., wallet for lnd, Grafana dashboards, etc.) are exposed behind this TOR site.

* `bitcoin` [required] -- the `bitcoin` lxd host is built for bitcoin-related services: A Bitcoin Core version 16.1 running as a fully-validating node provides the root of trust for global consensus operations [required]. One or more Lightning daemons may be deployed to the `bitcoin` lxd host as well. Users may choose which additional components should be deployed depending the expected use case, e.g., fully-validating node in pruned mode with c-lightning and BTCPay for a point-of-sale application). In all cases, daemon P2P services are configured to use TOR. Individual RPC interfaces may be exposed to distinct TOR onion sites. Like manager LXD containers, `bitcoin` uses `cachestack` to pull docker images.

* [NOT IMPLEMENTED] `elastic` -- you can deploy an elastic database and associated dashboards (grafana, kinbana). Other databases (e.g., graph database for lightning) will be made available as BCM is developed. All databases are fed with data from the Kafka messaging stack on the manager hosts.

* `app-hosts` -- hosts designed for user-specific code. Examples include hosting an Elastic database for visualizing data originating from a Kafka topic, stream processing to/from Kafka topics, or application-level event-based workflows. Developers choosing BCM as an operating platform create custom code and organize it here.

As mentioned, `cachestack` can be deployed in standalone mode, which is recommended when doing development on Bitcoin Cache Machine. In these cases, `cachestack` requires access to the underlay network to provide caching services to clients on your LAN (e.g., Bitcoin Cache Machine core components).

## Project Status

BCM is brand new and unstable. It is in a proof-of-concept stage. Don't put real bitcoin on it. Master branch is meant to be stable-ish. There are a lot of things that need to be done to it, especially in securing all the INTERFACES!!! I'm still working on core features; hardening and hardware-based cryptographic operations are next for integration.

## How to contribute

Users wanting to contribute to the project may submit pull requests for review. A Keybase Team has been created for those wanting to discuss project ideas and coordinate.

[Keybase Team for Bitcoin Cache Machine and Bitcoin Cache Stack](https://keybase.io/team/btccachemachine)