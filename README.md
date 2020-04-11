
# Bitcoin Cache Machine

Bitcoin Cache Machine is open-source software that allows you to create and manage one or more Bitcoin-focused privacy-preserving personal payment systems (perfect for long-term HODLers). BCM scripts allow you to quickly deploy a purely software-defined bitcoin payment stack to your local Ubuntu machine, or any Ubuntu-based SSH endpoint (e.g., SSH over LAN, SSH over Tor onion). BCM is built entirely with free and open-source software and is meant primarily for long-term Bitcoin HODLrs that want to run their own Bitcoin node infrastructure along with privacy-preserving technologies such as JoinMarket for on-chain UTXO management, and c-Lightning for access to Bitcoin's high-speed and low-free payment network, Lightning.

## Project Status

**IMPORTANT!** BCM is brand new and unstable, only use testnet coins! Builds will be formally tagged using [GPG.asc](./GPG.asc) once a stable proof-of-concept has been created. The master branch represents the most up-to-date stable, and tested, version of BCM. The 'dev' branch has the latest version of BCM.

BCM HAS NOT undergone formal security evaluation and should be considered for TESTING PURPOSES ONLY.

```YOU ASSUME ALL RISK IN USING THIS SOFTWARE!!!```

## Why Bitcoin Cache Machine Exists

If you're involved with Bitcoin or care about your privacy, you will undoubtedly understand the importance of [running your own fully-validating bitcoin node](https://medium.com/@lopp/securing-your-financial-sovereignty-3af6fe834603). Running a fully-validating node is easy enough--just download the software and run it on your home machine, but is that really enough to preserve your overall privacy? Did you configure it correctly? Are you also running a properly configured block explorer? Is your software up-to-date? Is your wallet software configured to consult your trusted full node (and ONLY your node)? Has TOR for these services been configured? Are you backing up user critical data in real time? In practice, there are ton of considerations that need to be addressed.

There are many areas where your privacy can be compromised if you're not careful. BCM is meant to handle many of these concerns by creating a software-defined data center at your home or office that's pre-configured to protect your overall privacy. If you can provide the necessary hardware (CPU, memory, disk), a LAN segment, and an internet gateway, BCM can do much of the rest. BCM dramatically lowers the barriers to deploying and operating your own bitcoin payment infrastructure.

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

## What is needed to Run Bitcoin Cache Machine

You need an x86 machine capable of running a Debian-based Linux. This hardware should have two SSDs (formatted to BTRFS, min 500GB each) and mounted at `/tier1`. `/tier1` storage holds the base OS (with KVM hypervisor), Type 1 VMs OSs and other software, and is where data meant for fast storage is kept, such as the bitcoin chainstate and Lightning-based software. The `/tier2` storage is composed of a set of USB-based SPINNING disks, all configured in the same BTRFS pool. Things like bitcoin blocks and local backups are stored.

## Roles & Responsiblities

There exists two distinct roles in the BCM ecosystem. The Hardware Administrator and the Software Administrator. The Hardware Admin is responsible for powering hardware, adding and configuring storage (i.e., `/tier1` storage composed of SSDs, and `/tier2` storage for high-capacity, reliable, scalable commodity storage.). The Hardware administrator is responsible for providing compute, memory, and storage consumable by the Software Administrator. The software administrator exects the following:

1. Compute
2. Memory
4. Reliable Internet connectivity
5. Mesh network connectivity to local metro area (for redundnacy)
3. Storage
3a. `/tier1` high speed dual-SSDs configured in BTRFS pool
3b. `/tier2` high capacity spinning disks in BTRFS pool
4. SSH connection to base OS along with static IP.

## Getting Started

The first step to getting started with Bitcoin Cache Machine get the BCM scripts (git repo) to your computer, a user-facing desktop or laptop running a Debian-based OS. The instructions below can be executed that will help you get started.

```bash
# download the BCM init script; VERIFY CONTENTS!
wget -o pull_bcm.sh https://raw.githubusercontent.com/BitcoinCacheMachine/BitcoinCacheMachine/dev/init_bcm.sh

# make the script executable then run it 
# scripts installs TOR, then git pulls the BCM source code from github 
# TODO 1) move from github to zeronet
chmod 0744 ./init_bcm.sh
sudo bash -c ./init_bcm.sh
```

The script above install the latest tor proxy, the pulls the BCM git clones the repo using TOR transport. Now that you have the code (in the bcm directory), you can decide how you want to deploy BCM. You can deploy it locally on bare-metal (best performance, good for single-user use) or in Type-1 VMs. Type 1 VMs are useful if you want to run multiple BCM instances on shared hardware (e.g., a full node for each family member). Finally, you can use BCM to deploy BCM server-side infrastructure to a remote SSH endpoint (or SSH exposed as an onion service).

After you have the BCM scripts, run the installer:

```bash
sudo bash -c ./install_bcm.sh
```

Next, decide how you want to run BCM:

. If you want to run BCM in Type-1 vms, use `./refresh_bcm.sh`.
  If you want to run BCM directly on your localhost, run `sudo bash -c ./install.sh`

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
