
# Bitcoin Cache Machine

Bitcoin Cache Machine is open-source software that allows you to create a self-hosted privacy-preserving [software-defined data-center](https://en.wikipedia.org/wiki/Software-defined_data_center). BCM is built entirely with free and open-source software and is meant primarily for home and small office use in line with the spirit of decentralization.

BCM is a set of BASH scripts that allows administrators to run bitcoin node infrastructure. We all know that it is unlikely that the "average Joe" will run their own Bitcoin infrastrcture. There are REAL costs associated with attaining self-soverignty. Running a high-uptime node infrastructure takes real skill and resources! However, most people know one or more people in their life that are "tech-savvy" and are able to run these software services for them. Like everything in life, trade-off exists. In this case, BCM is a set of software that is run by a person you trust (i.e., the neighborhood Geek/Nerd whose morals you trust). Your administrator should be someone you trust not to act in immoral or untrustworthy ways. Examples include millennial sons and daughters, computer-literate friends, local neighborhood anarchists, etc..

## Project Status

**IMPORTANT!** BCM is brand new and unstable, only use testnet coins! Builds will be formally tagged using [GPG.asc](./GPG.asc) once a stable proof-of-concept has been created. The master branch represents the most up-to-date stable, and tested, version of BCM. The 'dev' branch has the latest version of BCM.

BCM HAS NOT undergone formal security evaluation and should be considered for TESTING PURPOSES ONLY.

```YOU ASSUME ALL RISK IN USING THIS SOFTWARE!!!```

## Why Bitcoin Cache Machine Exists

If you're involved with Bitcoin or care about your privacy, you will undoubtedly understand the importance of [running your own fully-validating bitcoin node](https://medium.com/@lopp/securing-your-financial-sovereignty-3af6fe834603). Running a fully-validating node is easy enough--just download the software and run it on your home machine, but is that really enough to preserve your overall privacy? Did you configure it correctly? Are you also running a properly configured block explorer? Is your software up-to-date? Is your wallet software configured to consult your trusted full node (and ONLY your node)? Has TOR for these services been configured? Are you backing up user critical data in real time? In practice, there are ton of considerations that need to be addressed.

There are many areas where your privacy can be compromised if you're not careful. BCM is meant to handle many of these concerns by creating a software-defined data center at your home or office that's pre-configured to protect your overall privacy. If you can provide the necessary hardware (CPU, memory, disk), a LAN segment, and an internet gateway, BCM can do much of the rest. Bitcoin Cache Machine dramatically lowers the barriers to deploying and operating your own bitcoin payment infrastructure.

For more information about the motivations behind Bitcoin Cache Machine, visit the [public website](https://www.bitcoincachemachine.org/2018/11/27/introducing-bitcoin-cache-machine/).

## Development Goals

Here are some of the development goals for Bitcoin Cache Machine:

* Provide a self-contained, distributed, event-driven, software-defined data center that focuses on operational Bitcoin and Lightning-related IT infrastructure.
* Enable small-to-medium-sized scalability by adding commodity x86_x64 hardware for home and small office settings.
* Integrate free and open source software ([FOSS](https://en.wikipedia.org/wiki/Free_and_open-source_software))!
* Create a composable framework for deploying Bitcoin and Lightning-related components, databases, visualizations, web-interfaces, etc., allowing app developers to start with a fully-operational baseline data center.
* Automate the deployment and operation (e.g., backups, updates, vulnerability assessments, key and password management, etc.) of BCM deployments.
* Require hardware wallets for cryptographic operations (PGP, SSH, and Bitcoin transactions).
* Configure all software to protect user's privacy (e.g., TOR for external communication, disk encryption, minimal attack surface, etc.).
* Pursue [Global Consensus and Local Consensus Models](https://twitter.com/SarahJamieLewis/status/1016832509709914112) for core platform components, e.g., Bitcoin for global financial operations and [cwtch](https://openprivacy.ca/blog/2018/06/28/announcing-cwtch/) for asynchronous, multi-peer communications.
* Enhance overall security and performance and network health by running a Tor middle relay and serving bitcoin blocks over Tor.

## What is needed to Run Bitcoin Cache Machine

If you can run a modern Linux kernel and [LXD](https://linuxcontainers.org/lxd/), you can run BCM. BCM data-center workload components run as background server-side processes, so you'll usually want to have one or more always-on computers with a reliable Internet connection, especially if you're running something like BTCPay Server, which serves web pages (e.g., invoices) to external third parties or running a liquidity-providing Lightning node or acting a [JoinMarket](https://github.com/JoinMarket-Org/joinmarket-clientserver) maker. You can run BCM data-center workloads directly on your Ubuntu installation or it can run in a hardware-based VM using [multipass](https://github.com/CanonicalLtd/multipass). User-facing GUI applications such as Electrum Wallet run within the context of docker which is automatically installed via snap.

All you need to get started is an SSH endpoint running Ubuntu 18.04. When running BCM standalone such a user-facing desktop or laptop, data center workloads run within the context of [KVM-based Virtual Machine](https://www.linux-kvm.org/page/Main_Page) if supported by the hardware. README.md in the `cluster` directory has more details on prepping a bare-bones Ubuntu Server for a dedicated back-end server.

## Getting Started

The first step to getting started with Bitcoin Cache Machine get the BCM scripts (git repo) to your computer, a user-facing desktop or laptop running a Debian-based OS. Do the following to get the code.

```bash
# Verify init_bcm.sh
wget -o pull_bcm.sh https://raw.githubusercontent.com/BitcoinCacheMachine/BitcoinCacheMachine/dev/init_bcm.sh

# make the script executable then run; 
# scripts installs TOR, then git pulls the BCM source code from github
chmod 0744 ./init_bcm.sh
sudo bash -c ./init_bcm.sh
```

The script above install the latest tor proxy, the pulls the BCM git clones the repo to your pwd. Now that you have the code (in the bcm directory), you can decide how you want to deploy BCM. You can deploy it locally on bare-metal (best performance, good for single-user use) or in Type-1 VMs, which is useful if you want to run multiple BCM instances on a single set of hardware. You can also use BCM shell scripts to deploy BCM server-side infrastructure to a remote SSH endpoint (or SSH exposed as an onion service).

If you want to deploy locally, just run `bcm deploy`. If you want to run BCM in Type-1 vms, use BCM_GIT_DIR/test/refresh_bcm.sh.

## Deploying your own BCM Infrastructure

After the BCM CLI is available, you can deploy your own infrastructure using the `bcm stack start` command. For example, to deploy the `spark` lightning web wallet and all its dependencies including `clightning` and `bitcoind`, run the `bcm stack start spark` command. Other components you can deploy either alone or in combination with other software include:

| BCMStack | IsFunctional | AppType | DependsOn | InboundOutboundTor | AppServices
|---|---|---|---|---|---|
| tor | Yes | DC | tier bitcoin | n/a | n/a |
| bitcoind | Yes | DC | tor | p2p (in/out) | bitcoind_rpc |
| clightning | Yes | DC | bitcoind | p2p (in/out) | TBD |
| spark | Yes | DC/web app | clightning | none | HTTP |
| nbxplorer | Yes | DC | bitcoind | N/A | none |
| btcpayserver | Partially | DC/web app | bitcoind, clightning, nbxplorer, lightning-charge | TBD | HTTP |
| lnd | Partially | DC | bitcoind | p2p (in/out) | TBD |
| ridethelightning | No | DC/web app | lnd | N/A | HTTP |
| electrs | Yes | DC | bitcoind | none | ElectrumServerRPC |
| electrum | Yes | Desktop GUI | electrs | none | N/A |
| zap | No | Desktop GUI | zap | lnd | N/A |
| esplora | No | DC/web app | bitcoind, electrs | none | HTTP |
| lightning-charge | No | DC | clightning | none | TBD |
| liquid | No | DC | bitcoind | TBD | TBD |

`DC=data center`: processes that run in the "back-end" or "server-side". The back-end can run on a dedicated set Ubuntu machines (preferred for mainnet/production), or you can run the back-end on a user-facing desktop/laptop (useful for testnet/development). The back-end can run as a Type I VM or can be running under an LXD process installed on your localhost (local). There are trade-offs to using each approach (local/ssh/vm) which are discussed in more detail in the [Cluster directory](./cluster/README.md).

User-facing applications can be either GUI-based or web-based apps (AppType). Desktop GUI applications are fully integrated into an automatically deployed back-end infrastructure. Web-based applications, such as [BTCPay Server](https://btcpayserver.org/) or [Spark](https://github.com/shesek/spark-wallet) run as server-side data center workloads but are accessed through a web browser. The eventual goal is to expose BCM application-level services locally (console), over the local network using a Wireguard VPN, and through authenticated TOR onion services when accessing BCM services over the Internet.

Running `bcm stack start electrum` starts an Electrum wallet desktop application that's configured to consult a self-hosted Electrum server `electrs` which itself is configured to consult a self-hosted [Bitcoin Core](https://github.com/bitcoin/bitcoin) full node operating over [Tor](https://www.torproject.org/). Each `bcm stack start` command automatically deploys all required back-end infrastructure to the active cluster, helping you to operate in a more [trust-minimized manner](https://nakamotoinstitute.org/trusted-third-parties/).

You can use the `bcm info` command to view your current BCM environment variables: certificate, password, ssh, wallet, and certificate stores, cluster under management, and target chain (i.e., mainnet, testnet, regtest). Run `bcm config set chain=mainnet` to instruct the BCM cli to deploy mainnet applications to the active cluster. At this time BCM deploys a full archival node, so your hardware must be beefy enough. Future BCM versions will support pruned mode if all protocols support that.

## Documentation

The best documentation can be found using the CLI `--help` menus. You can also consult the README.md files in the major directories of this repo. Consult [CLI README](./commands/README.md) for notes on how to use the BCM CLI.

## Related Projects

Click the following link to view projects that are related to BCM:

NodeLauncher
CipherNode
Nodl.it
Casa

## How to contribute

Users wanting to contribute to the project may submit pull requests for review. See [CONTRIBUTING.md](./CONTRIBUTING.md). Users wanting to contribute documentation can fork the BCM public website [here](https://github.com/BitcoinCacheMachine/bcmweb) and add blog posts in the `_posts` directory.

You can also donate to the development of BCM by sending Bitcoin (BTC) to the following address.

* Public on-chain donations: 3KNX4GTmXETtnFWFXvFqXg9sDJCbLvD8Zf
