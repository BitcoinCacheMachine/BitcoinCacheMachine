
# <img src="./resources/bcmlogo_super_small.png" alt="Bitcoin Cache Machine Logo" style="float: left; margin-right: 20px;" /> Bitcoin Cache Machine

Bitcoin Cache Machine (BCM) is an event-driven, software-defined data center created for developers, individuals, and small businesses wanting to own and operate their own bitcoin-related payment infrastructure. It's a Personal Financial Operating System (PFOS) based entirely on the ONLY secure blockchain--Bitcoin (as determined by the fabulous open-source implementation we call Bitcoin Core)! It's a platform for your Bitcoin-based business.

**IMPORTANT! BCM is intended for testing purposes ONLY! It is very new and under heavy development by a single author and HAS NOT undergone a formal security evaluation and it is VERY likely to have vulnerabilities. USE AT YOUR OWN RISK!!!**

BCM deploys in a fully automated way and runs on bare-metal Linux, in a VM, on-premise (preferred), or in the cloud (i.e., on someone elses computer!). It's consists entirely of open-source software. BCM is MIT licensed, so fork away and feel free to submit pull requests with your awesome ideas for improvement!

## Why Bitcoin Cache Machine Exists

If you're involved with Bitcoin, you will undoubtedly understand the importance of [running your own fully-validating bitcoin node](https://medium.com/@lopp/securing-your-financial-sovereignty-3af6fe834603) and operating your own IT infrastructure. Running a fully-validating node is easy enough--just download the software and run it on your home machine, but is that really enough to preserve your overall privacy? Did you configure it correctly? Are you also running a properly configured block explorer? Is your software up-to-date? Is your wallet software configured to consult your trusted full node? Has TOR for these services been tested properly? Are you routing your DNS queries over TOR? Are you backing up user critical data in real time?

There are tons of other areas where your privacy can be compromised if you're not careful. BCM is meant to handle these concerns by creating a privacy-centric software-defined home and office automation network. It's a self-hosted software-defined data center for Bitcoin maximalists.

Bitcoin Cache Machine dramatically lowers the barriers to deploying and operating your own bitcoin payment infrastructure. If you can provide the necessary hardware (CPU, memory, disk), a LAN segment, and an internet gateway, BCM can do much of the rest.

## Goals of Bitcoin Cache Machine

Below you will find some of the development goals for BCM.

* Provide a self-contained, event-driven, software-defined network that deploys a fully operational Bitcoin and Lightning-related IT infrastructure.
* Run entirely on commodity x86_x64 hardware for home and small office settings. Run on bare-metal or in a self-hosted or cloud-based VM.
* Integrate exclusively free and open source software ([FOSS](https://en.wikipedia.org/wiki/Free_and_open-source_software))!
* Create a composable framework for deploying Bitcoin and Lightning-related components, databases, visualizations, web-interfaces, etc., allowing app developers to start with a fully operational baseline.
* Automate the deployment and operation (e.g., backups, updates, vulnerability assessments, key and password management, etc.) of each BCM deployment.
* Embrace hardware wallets for cryptographic operations where possible (e.g., Trezor-generated SSH keys or PGP certificates for authentication and encryption).
* Pre-configure all software to protect user's privacy (e.g., TOR for external communication, disk encryption, minimal attack surface, etc.).
* Pursue [Global Consensus and Local Consensus Models](https://twitter.com/SarahJamieLewis/status/1016832509709914112) for core platform components, e.g., Bitcoin for global financial operations and [cwtch](https://openprivacy.ca/blog/2018/06/28/announcing-cwtch/) for asynchronous, multi-peer communications, etc..

## How to Run Bitcoin Cache Machine

`BCM SHOULD BE CONSIDERED FOR TESTING PURPOSES ONLY!!! IT HAS NOT UNDERGONE A FORMAL SECURITY EVALUATION!!!`

If you can run a modern Linux kernel and [LXD](https://linuxcontainers.org/lxd/), you can run BCM. You can run BCM in a hardware-based VM, directly on bare-metal, or in "the cloud". Bitcoin Cache Machine components are deployed exclusively over the [LXD REST API](https://github.com/lxc/lxd/blob/master/doc/rest-api.md), so you can deploy BCM to any LXD-capable endpoint! LXD is widely available on various free and open-source linux platforms. BCM has been developed and primarily tested using Ubuntu 18.04.

Documentation can be found in each directory and in the wiki. Readme files in each directory tell you what you need to know about deploying the various infrastructure components at that level. [README.md](./multipass/README.md) details the requirements for running BCM in a multipass-based VM and provides simple instructions for getting started. But before you begin, clone this repository to your machine--the machine that will execute BCM shell (BASH) scripts. In the documentation, this machine is referred to as the `admin machine` since it manages sensitive information (passwords, certificates, etc.) and is required for administrative installations or changes.

Clone the BCM reference implementation on to the `admin machine` and cd into the root of the repository. Open a terminal then run the following commands to get started:

```bash
mkdir -p ~/git/github/bcm
git clone https://github.com/BitcoinCacheMachine/BitcoinCacheMachine ~/git/github/bcm
cd ~/git/github/bcm
./setup.sh
```

`./setup.sh` prepares the `admin machine` for using BCM scripts. This script creates the directory ~/.bcm, which is where BCM scripts store and manage sensitive BCM deployment options and runtime files. Click [here](./setup_README.md) for more information.

To continue, consider running [BCM in a multipass-based VM](./multipass). Click [here](./wiki/installation/baremetal.md) if you want to run BCM on a computer running Linux (i.e., bare-metal).

## Bitcoin Cache Machine Component

First, it is important that Bitcoin Cache Machine is designed to be composable. The components listed below may be deployed depending on the desired use case. Second is to remember that the components listed below are simply LXD

Each Bitcoin Cache Machine deployment includes one or more of the following components:

* `gateway` - an lxc container that provides essential network services for BCM deployments. `gateway` isn't strictly necessary, but having one on your network greatly improves your privacy and improves the overall experience. `gateway` runs [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) which provides DHCP and DNS services for your physical network home or office network. *From the perspective of BCM, this is the physical underlay network*. BCM components, e.g., cachestack, managers, bitcoin, elastic, etc., SHOULD be deployed on `gateway` *physical underlay network*, aka `trusted inside` network. `gateway` allows outbound outbound traffic (i.e., ip forwarding) from the `trusted inside` to `untrusted outside` according to a strict firewall policy, only TCP 9050 (TOR) traffic is allowed. This ensures that all traffic originating on the `trusted inside` is configured to use TOR. More details about `gateway` and its operation can be found at ./lxd/gateway/README.md.

* `cachestack` - a set of LXD components that primarily provide caching services for other BCM components. `cachestack` MAY be installed in either standalone mode  (essential for development), in which case it provides caching services to devices on your network, or 2) in combination with other BCM components. Certain BCM components are dependent on one or more caching services that are expected to be hosted on a `cachestack`. If there is no standalone `cachestack` on your LAN segment, BCM installs a local copy and uses it internally; that is, BCM is dependent on a `cachestack` existing. Each `cachestack` hosts a Docker registry mirror configured as a pull-through cache and a private docker registry to store images emitted after the docker image build process.  More information about the `cachestack` and its components can be found at ./lxd/cachestack/README.md.

* `manager1` [required], `manager2` [optional], `manager3` [optional] -- There are manager LXD hosts that 1) provides container service orchestration using [Docker Swarm Mode](https://docs.docker.com/engine/swarm/), and 2) hosts a docker stack that provides event messaging services based on [Apache Kafka](https://kafka.apache.org/). Dependent LXD hosts, e.g., `bitcoin`, `app_host` are configured to LOG messages to one or more upstream `manager` hosts. The docker-ce daemon on each manager host is configured to use a docker registry mirror hosted on an upstream `cachestack`. A Kafka messaging stack is deployed to each manager node for distributed messaging and is the system-of-record for event data. More information on `manager` hosts can be found in "$BCM_LOCAL_GIT_REPO/lxd/managers/README.md".

* `bitcoin` -- the `bitcoin` lxd host is built for bitcoin-related services. The dockerd daemon on any `bitcoin` BCM instance is configured to log messages via TCP-based GELF to a `manager` instance which runs a GELF listener. The `bitcoin` LXC host is capable of running a Bitcoin Core full node, one or more Lightning daemons, applications like BTCPay, lightning-charge, etc.. Users may choose which additional components to deploy depending the expected use case. All daemons running on a `bitcoin` BCM instance are configured use TOR for outbound communication. Individual services, e.g,. bitcoind RPC, lnd gRPC, c-lightning RPC, lightning-charge REST API, etc., MAY be exposed as authenticated TOR onion sites.

* `app_host` -- hosts designed for user applications. Each app_host can be named according to user requirements, examples include hosting an `elastic` database for visualizing data originating from a Kafka topic, or perhaps `streamhost` for stream processing to/from Kafka topics. Developers choosing BCM as an operating platform create custom code and organize it here. /lxd/app_host/README.md provides BASH scripts for provisioning each `app_host`. Users simply develop associated `$BCM_LOCAL_GIT_REPO/docker_stack` files `$BCM_LOCAL_GIT_REPO/docker_image` files to deploy a custom app.

## Project Status

BCM is brand new and unstable. It is in a proof-of-concept stage. Don't put real bitcoin on it. Stable builds will be formally tagged, but we're not there yet. There are a lot of things that need to be done to it, especially in securing all the INTERFACES!!!

## How to contribute

Users wanting to contribute to the project may submit pull requests for review. A Keybase Team has been created for those wanting to discuss project ideas and coordinate.

[Keybase Team for Bitcoin Cache Machine](https://keybase.io/team/btccachemachine)