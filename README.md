
# <img src="./resources/bcmlogo_super_small.png" alt="Bitcoin Cache Machine Logo" style="float: left; margin-right: 20px;" /> Bitcoin Cache Machine

Bitcoin Cache Machine (BCM) is an event-driven, software-defined data center created for developers, individuals, and small businesses wanting to own and operate their own bitcoin-related payment infrastructure. It's a Personal Financial Operating System (PFOS) based entirely on the ONLY secure blockchain--Bitcoin (as determined by the fabulous open-source implementation we call Bitcoin Core)! It's a platform for your Bitcoin-based business.

**IMPORTANT! BCM is intended for evaluation purposes ONLY! It is very new and under heavy development by a single author and HAS NOT undergone a formal security evaluation! Only Bitcoin TESTNET is supported at this time. USE AT YOUR OWN RISK!!!**

BCM deploys in a fully automated way and runs on bare-metal Linux, in a VM, on-premise (preferred), or in the cloud (i.e., on someone elses computer!). It's consists entirely of open-source software. BCM is MIT licensed, so fork away and feel free to submit pull requests with your awesome ideas for improvement!

## Why Bitcoin Cache Machine Exists

If you're involved with Bitcoin, you will undoubtedly understand the importance of [running your own fully-validating bitcoin node](https://medium.com/@lopp/securing-your-financial-sovereignty-3af6fe834603) and operating your own IT infrastructure. Running a fully-validating node is easy enough--just download the software and run it on your home machine, but is that really enough to preserve your overall privacy? Did you configure it correctly? Are you also running a properly configured block explorer? Is your software up-to-date? Is your wallet software configured to consult your trusted full node? Has TOR for these services been tested properly? Are you routing your DNS queries over TOR? Are you backing up user critical data in real time?

There are tons of other areas where your privacy can be compromised if you're not careful. BCM is meant to handle these concerns by creating a privacy-centric software-defined home and office automation network. It's a self-hosted software-defined data center for Bitcoin maximalists.

Bitcoin Cache Machine dramatically lowers the barriers to deploying and operating your own bitcoin payment infrastructure. If you can provide the necessary hardware (CPU, memory, disk), a LAN segment, and an internet gateway, BCM can do much of the rest. You can improve overall performance and enable more rapid development by installing a standalone `cachestack` component on your network! `cachestack` is especially useful when developing new line of business applications on top of Bitcoin Cache Machine!

## Goals of Bitcoin Cache Machine

Below you will find some of the development goals for BCM.

* Provide a self-contained, event-driven, software-defined IT infrastructure for potential Bitcoin and Lightning-related applications.
* Run entirely on commodity x86_x64 hardware for home and small office settings. Run on bare-metal or in a self-hosted or cloud-based VM.
* Integrate exclusively free and open source software ([FOSS](https://en.wikipedia.org/wiki/Free_and_open-source_software))!
* Create a composable framework for deploying Bitcoin and Lightning-related components, databases, visualizations, web-interfaces, etc..
* Automate the deployment and operation (e.g., backups, updates, vulnerability assessments, key and password management, etc.) of each BCM deployment.
* Embrace hardware wallets for cryptographic operations where possible (e.g., Trezor-generated SSH keys or PGP certificates for authentication and encryption).
* Pre-configure all software to protect user's privacy (e.g., TOR for communication, disk encryption, minimal attack surface, etc.).
* Embrace decentralization and sovereignty of the individual (i.e., [Anarchy](https://en.wikipedia.org/wiki/Anarchy)).
* Pursue [Global Consensus and Local Consensus Models](https://twitter.com/SarahJamieLewis/status/1016832509709914112) for core platform components.

The trusted root of each BCM deployment from a [global consensus perspective](https://fieldnotes.resistant.tech/dags-and-decentralization/) is Bitcoin, the only censorship-resistant blockchain.

## How to Run Bitcoin Cache Machine

`BCM SHOULD BE CONSIDERED FOR TESTING PURPOSES ONLY!!! IT HAS NOT UNDERGONE A FORMAL SECURITY EVALUATION!!!`

If you can run a modern Linux kernel and [LXD](https://linuxcontainers.org/lxd/), you can run BCM. You can run BCM in a hardware-based VM, directly on bare-metal, or in "the cloud". Bitcoin Cache Machine is deployed exclusively over the [LXD REST API](https://github.com/lxc/lxd/blob/master/doc/rest-api.md), so you can deploy BCM to any LXD-capable endpoint! LXD is widely available on various free and open-source linux platforms. BCM has been developed and primarily tested using Ubuntu 18.04.

Documentation can be found in each directory starting at ./multipass. Readme files in each directory tell you what you need to know about deploying the various infrastructure components at that level. [README.md](./multipass/README.md) details the requirements for running BCM in a multipass-based VM and provides simple instructions for getting started. But before you begin, clone this repository to your machine--the machine that will execute BCM shell (BASH) scripts. In the documentation, this machine is referred to as the `admin machine` since it manages sensitive information (passwords, certificates, etc.) and is required for administrative installations or changes.

Download the BCM git repo to the `admin machine` and cd into the root of the repo. All documentation in this repo assumes you have cloned the repo to `~/git/github/bcm` which is considered the BCM repo root directory.

```bash
mkdir -p ~/git/github/bcm
git clone https://github.com/BitcoinCacheMachine/BitcoinCacheMachine ~/git/github/bcm
cd ~/git/github/bcm
```

Next, run `./setup.sh` on the `admin machine`. This script creates the directory ~/.bcm, which is where you BCM scripts source BCM deployment options and to store runtime files. Click [here](./resources/README.md) for more information.

To continue, consider running [BCM in a multipass-based VM](./multipass). Click [here](./docs/installation/baremetal.md) if you want to run BCM on a computer running Linux (i.e., bare-metal).

## BCM Components

Bitcoin Cache Machine is where your bitcoin-related workloads reside. BCM instances are meant to be horizontally scalable by adding commodity hardware (PLANNED, see [LXD Clustering](https://lxd.readthedocs.io/en/latest/clustering/).

Each Bitcoin Cache Machine deployment includes one or more of the following components:

* `underlay` - an LXD container that provides DHCP and DNS services for your physical network (i.e., the underlay). The `underlay` container currently connects to an untrusted outside and trusted inside interface which MUST be explicitly set by the administrator (see ./resources/defaults/underlay.env). DHCP and DNS is served to clients on the trusted inside interface. `underlay` can also be configured to forward arbitrary traffic out the untrusted interface. The outside interface obtains IP and routing information from a DHCP server upstream, such as a DSL or cable modem. The untrusted outside interface firewall policy disallows all incoming connections. The DNS server on exposed on the inside interface is configured to use TOR for outbound external queries and cache known entries for local LAN clients. DHCP clients requesting an address SHOULD provide a hostname which is auto-pushed into the DNS. A properly working `underlay` makes BCM deployments far easier and consistent because we know addressing and DNS are correctly configured!

* `cachestack` - a set of LXD components that primarily provide caching services for local and remote BCM components. `cachestack` is installed in either standalone mode, in which case it provides caching services to devices on your network, or 2) in combination with other BCM components. Certain BCM components MAY be dependent on one or more `cachestack` services. If there is no standalone `cachestack` on your LAN segment, BCM installs a local copy and uses it internally; that is, BCM is dependent on a `cachestack`.  More information about the `cachestack` and its components can be found in ./docs/architecture/cache_stack.md. Future versions of `cachestack` will include DHCP with hostname auto-registration and a DNS cache configured to use TOR.


* `manager1` [required], `manager2` [optional], `manager3` [optional] -- There are manager LXD hosts to to facilitate the Docker Swarm manager role for the rest of the swarm. The docker-ce daemon on each manager host is configured to use `cachestack` as the Docker registry mirror. A Kafka messaging stack is deployed to each manager node for distributed messaging and is the system-of-record for event data. Manager LXC containers MAY be deployed to independent x86_x64 hardware for local high-availability using LXD clustering (PLANNED).

* `bitcoin` [required] -- the `bitcoin` lxd host is built for bitcoin-related services: A Bitcoin Core version 16.1 running as a fully-validating node provides the root of trust for global consensus operations [required]. One or more Lightning daemons may be deployed to the `bitcoin` lxd host as well. Users may choose which additional components to deploy depending the expected use case. Whenever possible, daemon P2P services are configured to use TOR. In addition, individual RPC interfaces (e.g., lnd GRPC interface) may be exposed at unique TOR onion sites. This allows mobile apps to securely connect and directly control their Lightning infrastructure. Like manager LXD containers, `bitcoin` uses a `cachestack` (either local or a networked standalone `cachestack`) to pull docker images. The [docker-ce]("https://docs.docker.com/install/#next-release") daemon on `bitcoin` is configured to log via GELF to a logstash-based GELF listener on `manager1`; logs are stored in Kafka. PLANNED - log messages will be converted stored in AVRO using [Kafka Schema Registry]("https://github.com/confluentinc/schema-registry"). PLANNED - implement kafka schema-evolution.

* [NOT IMPLEMENTED] `elastic` -- you can deploy an elastic database and associated dashboards (grafana, kinbana). Other databases (e.g., graph database for lightning) will be made available as BCM is developed. All databases are fed with data from the Kafka messaging stack on the manager hosts.

* `app-hosts` -- hosts designed for user-specific code. Examples include hosting an Elastic database for visualizing data originating from a Kafka topic, stream processing to/from Kafka topics, or application-level event-based workflows. Developers choosing BCM as an operating platform create custom code and organize it here.

As mentioned, `cachestack` can be deployed in standalone mode, which is recommended when doing development on Bitcoin Cache Machine. In these cases, `cachestack` requires access to the underlay network to provide caching services to clients on your LAN (e.g., Bitcoin Cache Machine core components).

## Project Status

BCM is brand new and unstable. It is in a proof-of-concept stage. Don't put real bitcoin on it. Master branch is meant to be stable-ish. There are a lot of things that need to be done to it, especially in securing all the INTERFACES!!! I'm still working on core features; hardening and hardware-based cryptographic operations are next for integration.

## How to contribute

Users wanting to contribute to the project may submit pull requests for review. A Keybase Team has been created for those wanting to discuss project ideas and coordinate.

[Keybase Team for Bitcoin Cache Machine and Bitcoin Cache Stack](https://keybase.io/team/btccachemachine)