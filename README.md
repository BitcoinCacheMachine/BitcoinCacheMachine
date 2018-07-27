
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

There are tons of other areas where your privacy can be compromised if you're not careful. BCM is meant to handle these concerns by creating a privacy-centric software-defined home or office automation network.

Bitcoin Cache Machine dramatically lowers the barrier to deploying and operating your own privacy-centric bitcoin payment infrastructure. If you can provide the necessary hardware (CPU, memory, disk), a LAN segment, and an Internet gateway, BCM can do much of the rest. Improve performance and privacy of your BCM deployment by installing a [Cache Stack](https://github.com/farscapian/bcm_cachestack)! The Cache Stack is especially useful when developing new line of business application on top of Bitcoin Cache Machine, but is entirely optional!

## Goals of Bitcoin Cache Machine

Below you will find some of the development goals for BCM.

* Provide a self-contained, event-driven, software-defined IT infrastructure for potential Bitcoin and Lightning-related applications.
* Be able to run entirely on commodity x86_x64 hardware for home and small office settings. You can run BCM on an old computer!
* Integrate exclusively free and open source software!
* Create a composable framework for deploying Bitcoin and Lightning-related components.
* Automate the deployment and operation (e.g., backups, updates, vulnerability assessments, key and password management, etc.) of each BCM deployment.
* Embrace hardware wallets for cryptographic operations where possible (e.g., Trezor-generated SSH keys or PGP certificates for authentication and encryption).
* Pre-configure all software to protect user's privacy (e.g., TOR for communication, disk encryption, minimal attack surface, etc.).
* Embrace decentralization and sovereignty of the individual (i.e., [Anarchy](https://en.wikipedia.org/wiki/Anarchy)).
* Pursue [Global Consensus and Local Consensus Models](https://twitter.com/SarahJamieLewis/status/1016832509709914112) for core platform components.

The trusted root of each BCM deployment from a [global consensus perspective](https://fieldnotes.resistant.tech/dags-and-decentralization/) is Bitcoin, the most secure and accomplished blockchain.

## How to Run BCM

If you can run modern Ubuntu, you can run BCM. BCM runs on bare-metal Ubuntu 18.04 or can operate inside a hardware-based VM. Please remember that BCM is for testing purposes only and is under heavy development. REPEAT!!!! BCM SHOULD BE CONSIDERED FOR TESTING PURPOSES ONLY!

You can run BCM in several ways:

* In a QEMU/KVM-based VM (see ./docs/installation/multipass.md)
* On bare-metal (see ./docs/baremetal.md) running Ubuntu 18.04.
* On someone elses computer (discouraged, but if you must) (see ./docs/installation/inthecloud_aws.md)

BCM is meant for home and small office use which aligns with the spirit of decentralization. BCM is meant to provide a performant and secure software-defined network for LAN segments (Layer 3 broadcast domains).

## BCM Components

Bitcoin Cache Machine is where your bitcoin-related workloads reside. BCM instances are meant to be horizontally scalable by adding commodity hardware. 

Each BCM is composed of the following:

* `cachestack` - a set of LXD components (networks, storage pool, profiles, etc.) and LXD containers that provide caching and underlay services for BCM components. You can install `cachestack` in standalone mode to provide network services to your LAN components. If there is no CacheStack on your LAN segment, Bitcoin Cache Machine installs a local copy and uses it internally. Cache Stack serves LXD images to your local network (when in standalone mode), hosts one or more Docker Registries configured as a pull-through cache, provides HTTP/HTTPS proxy services, and hosts an outbound SOCKS5 TOR proxy.

* `manager1` [required] -- There are manager hosts to facilitate the Docker Swarm manager role for the rest of the swarm. The docker daemon on each manager host is configured to use `cachestack:5000` as the Docker registry mirror. A Kafka messaging stack is deployed to each manager node for distributed messaging and is the system-of-record for user data. Manager LXC containers are planned to be deployable to independent x86_x64 hardware for high-availability.

* `bitcoin` [required] -- the `bitcoin` lxd host is built for bitcoin-related services: A Bitcoin Core version 16.1 running as a fully validating node provides the root of trust for global consensus operations [required]. One or more Lightning Daemons (currently c-lightning and lnd) can be deployed to the bitcoin host as well. The docker daemon on each app host is configured to obtain images from a docker registry mirror running on the proxyhost (since proxyhost serves a local registry cache).

* `app-hosts` -- special hosts designed for application-specific use cases. Examples include hosting an Elastic database for visualizing data originating from a Kafka topic, stream processing to/from Kafka topics, or application-level event-based workflows. Developers choosing BCM as an operating platform create custom code and organize it here.

Each the LXD host types is based on a LXD host template called [bcm_host_template](https://github.com/farscapian/bcm_host_template) which is shared by Bitcoin Cache Machine and the independently deployable Cache Stack.

## Project Status

BCM is brand new and unstable. It is in a proof-of-concept stage. Don't put real bitcoin on it. Master branch is meant to be stable-ish. There are a lot of things that need to be done to it, especially in securing all the INTERFACES!!! I'm still working on core features; hardening and hardware-based cryptographic operations are next for integration.

## How to contribute

Users wanting to contribute to the project may submit pull requests for review. A Keybase Team has been created for those wanting to discuss project ideas and coordinate.

[Keybase Team for Bitcoin Cache Machine and Bitcoin Cache Stack](https://keybase.io/team/btccachemachine)