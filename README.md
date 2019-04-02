
# <img src="./resources/images/bcmlogo_super_small.png" alt="Bitcoin Cache Machine Logo" style="float: left; margin-right: 20px;" /> Bitcoin Cache Machine

Bitcoin Cache Machine is open-source software that allows you to create a self-hosted privacy-preserving [software-defined data-center](https://en.wikipedia.org/wiki/Software-defined_data_center). BCM is built entirely with free and open-source software and is meant primarily for home and small office use in line with the spirit of decentralization.

> Note! Bitcoin Cache Machine REQUIRES a [Trezor-T](https://trezor.io/) to function! Consider buying a dedicated device for your BCM data center, or use [passphrases](https://wiki.trezor.io/Multi-passphrase_encryption_(hidden_wallets)) to maintain distinct keyspace.

## Project Status

**IMPORTANT!** BCM is brand new and unstable. It is in a proof-of-concept stage and deploys to bitcoin TESTNET mode only. Not all features are implemented. Don't put real bitcoin on it. Builds will be formally tagged once a stable proof-of-concept has been created. YOU ASSUME ALL RISK IN USING THIS SOFTWARE!!!

## Why Bitcoin Cache Machine Exists

If you're involved with Bitcoin or care about your privacy, you will undoubtedly understand the importance of [running your own fully-validating bitcoin node](https://medium.com/@lopp/securing-your-financial-sovereignty-3af6fe834603). Running a fully-validating node is easy enough--just download the software and run it on your home machine, but is that really enough to preserve your overall privacy? Did you configure it correctly? Are you also running a properly configured block explorer? Is your software up-to-date? Is your wallet software configured to consult your trusted full node? Has TOR for these services been tested properly? Are you routing your DNS queries over TOR? Are you backing up user critical data in real time?

There are many areas where your privacy can be compromised if you're not careful. BCM is meant to handle many of these concerns by creating a software-defined data center at your home or office that's pre-configured to protect your overall privacy. BCM is a distributed system, so it gets faster and more reliable as you add independent commodity hardware. If you can provide the necessary hardware (CPU, memory, disk), a LAN segment, and an internet gateway, BCM can do much of the rest. Bitcoin Cache Machine dramatically lowers the barriers to deploying and operating your own bitcoin payment infrastructure.

For more information about the motivations behind Bitcoin Cache Machine, visit the [public website](https://www.bitcoincachemachine.org/2018/11/27/introducing-bitcoin-cache-machine/).

## Development Goals

Here are some of the development goals for Bitcoin Cache Machine:

* Provide a self-contained, distributed, event-driven, software-defined data center that focuses on operational Bitcoin and Lightning-related IT infrastructure.
* Enable small-to-medium-sized scalability by adding commodity x86_x64 hardware for home and small office settings.
* Integrate free and open source software ([FOSS](https://en.wikipedia.org/wiki/Free_and_open-source_software))!
* Create a composable framework for deploying Bitcoin and Lightning-related components, databases, visualizations, web-interfaces, etc., allowing app developers to start with a fully-operational baseline data center.
* Automate the deployment and operation (e.g., backups, updates, vulnerability assessments, key and password management, etc.) of BCM deployments.
* Require hardware wallets for cryptographic operations (PGP, SSH, and Bitcoin transactions).
* Pre-configure all software to protect user's privacy (e.g., TOR for external communication, disk encryption, minimal attack surface, etc.).
* Pursue [Global Consensus and Local Consensus Models](https://twitter.com/SarahJamieLewis/status/1016832509709914112) for core platform components, e.g., Bitcoin for global financial operations and [cwtch](https://openprivacy.ca/blog/2018/06/28/announcing-cwtch/) for asynchronous, multi-peer communications.
* Enhance overall security and performance and network health by running a Tor middle relay and serving bitcoin blocks over Tor.
* Facilitate local (SSH) and remote using [SSH port-forwarding](https://help.ubuntu.com/community/SSH/OpenSSH/PortForwarding) with TOR transport for cluster administration.

## What is needed to Run Bitcoin Cache Machine

If you can run a modern Linux kernel and [LXD](https://linuxcontainers.org/lxd/), you can run BCM. BCM data-center workload components run as background server-side processes, so you'll usually want to have one or more always-on computers with a reliable Internet connection, especially if you're running something like BTCPay Server, which serves web pages (e.g., invoices) to external third parties or running a liquidity-providing Lightning node. User-facing GUI applications such as Electrum Wallet are containerized. You can run BCM data-center workloads in a hardware-based VM (default) or directly on bare-metal.

All you need to get started is an SSH endpoint running Ubuntu 18.04. When running BCM standalone such a user-facing desktop or laptop, data center workloads run within the context of [KVM-based Virtual Machine](https://www.linux-kvm.org/page/Main_Page) if supported by the hardware. README.md in the `cluster` directory has more details on prepping a bare-bones Ubuntu Server for a dedicated back-end server.

## Getting Started

The first step to getting started with Bitcoin Cache Machine is to clone the git repo to your new SDN controller, a user-facing desktop or laptop.

> NOTE: All BCM documentation ASSUMES you're working from a fresh install of Ubuntu (Desktop or Server) >= 18.04. Windows and MacOS are not directly supported, though you can always run Ubuntu in a VM. This goes for both the user-facing SDN controller and [dedicated back-end x86_64 data center hardware](https://github.com/BitcoinCacheMachine/BitcoinCacheMachine/tree/master/cluster#how-to-prepare-a-physical-server-for-bcm-workloads).

Start by installing [`tor`](https://www.torproject.org/) and [`git`](https://git-scm.com/downloads) from your SDN Controller. Next, configure your local `git` client to clone the BCM github repository using TOR for transport. This prevents github.com (i.e., Microsoft) from recording your real IP address. (It might also be a good idea to use a TOR browser when browsing this repo directly on github.).

```bash
sudo apt-get update
sudo apt-get install -y tor git
BCM_GITHUB_REPO_URL="https://github.com/BitcoinCacheMachine/BitcoinCacheMachine"
git config --global http.$BCM_GITHUB_REPO_URL.proxy socks5://localhost:9050
```

You can now clone the BCM repository to your machine over TOR and run setup. You can update your local BCM git repo by running `git pull` from `$BCM_GIT_DIR`.

```bash
export BCM_GIT_DIR="$HOME/git/github/bcm"
mkdir -p "$BCM_GIT_DIR"
git clone "$BCM_GITHUB_REPO_URL" "$BCM_GIT_DIR"
cd "$BCM_GIT_DIR"
./setup.sh
source ~/.bashrc
```

Feel free to change the directory in which you store the BCM repository on your machine. Just update the `BCM_GIT_DIR` variable. `setup.sh` sets up your SDN Controller so that you can use Bitcoin Cache Machine's CLI. Since `setup.sh` modifies group membership, you will have to log out and log back in before the BCM CLI operates correctly. Running `bcm` at the terminal builds the docker images needed to run bcm commands. The first place you should look for help is the CLI `--help` menus, e.g., `bcm --help`.

## Deploying your own BCM Infrastructure

After the BCM CLI is available, you can deploy your own infrastructure using the `bcm stack deploy` command. For example, to deploy the `spark` lightning web wallet and all its dependencies including `clightning` and `bitcoind`, run the `bcm stack deploy spark` command. Other supported components you can deploy include:

```bash
bcm stack deploy bitcoind
bcm stack deploy clightning
bcm stack deploy spark
bcm stack deploy btcpayserver
bcm stack deploy esplora
bcm stack deploy electrum
```

You can run GUI-based applications that are fully integrated into your automatically deployed back-end infrastructure. User-facing applications can also include web-based applications, such as [BTCPay Server](https://btcpayserver.org/) or [Spark](https://github.com/shesek/spark-wallet). Try running `bcm deploy electrum` to run a container-based Electrum wallet that is configured to consult a self-hosted Electrum server `electrs` which itself is configured to consult a self-hosted [Bitcoin Core](https://github.com/bitcoin/bitcoin) full node operating over [Tor](https://www.torproject.org/). Each `bcm stack deploy` command automatically deploys all required back-end infrastructure, helping you to operate in a more [trust-minimized manner](https://nakamotoinstitute.org/trusted-third-parties/).

You can use the `bcm info` command to view your current BCM environment variables: certificate, password, ssh, wallet, and certificate stores as well as the current cluster that under management, and target chain (i.e., mainnet, testnet, regtest) and BCM version. Consult [CLI README](./cli/README.md) for notes on how to use the BCM CLI. If you have deployed infrastructure, you can access CLI interfaces, e.g,. `bcm bitcoin-cli getnetworkinfo` or `bcm lightning-cli getinfo`. The BCM CLI routes your CLI request to the appropriate app-level container.

## Documentation

Documentation for BCM can be found on the [BCM Docs](https://www.bitcoincachemachine.org/docs/) public website.  It's definitely an area that needs work. In the meantime, consult the README.md files in the major directories of this repo.

## How to contribute

Users wanting to contribute to the project may submit pull requests for review. Users wanting to contribute documentation can fork the BCM public website [here](https://github.com/BitcoinCacheMachine/bcmweb) and add blog posts in the `_posts` directory. A Keybase Team has been created for those wanting to discuss project ideas and coordinate. [Keybase Team for Bitcoin Cache Machine](https://keybase.io/team/btccachemachine)

You can also donate to the development of BCM by sending Bitcoin (BTC) to the following address.

* Public on-chain donations: 3KNX4GTmXETtnFWFXvFqXg9sDJCbLvD8Zf

[<img src="./resources/images/onchain_public_donation_address.png" alt="BCM Donation Address" height="250" width="250">](bitcoin:3KNX4GTmXETtnFWFXvFqXg9sDJCbLvD8Zf)