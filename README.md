
# <img src="./resources/bcmlogo_super_small.png" alt="Bitcoin Cache Machine Logo" style="float: left; margin-right: 20px;" /> Bitcoin Cache Machine

Bitcoin Cache Machine is open-source software that implements a self-hosted, privacy-centric, software-defined network. BCM is built entirely with free and open-source software and is meant primarily for home and small office use in line with the spirit of decentralization. Its broad purpose is to software-define your home, office, or cloud networks with resilient privacy-preserving Bitcoin-related payment and operating IT infrastructure.

> **IMPORTANT!**
> BCM is intended for testing purposes ONLY! It is very new and under heavy development by a single author and HAS NOT undergone a formal security evaluation and it is VERY likely to have vulnerabilities. USE AT YOUR OWN RISK!!!**

BCM deploys in a fully automated way and runs on bare-metal Linux, in a VM, on-premise (preferred), or in the cloud (i.e., on someone elses computer!). It's consists entirely of open-source software. BCM is MIT licensed, so fork away and feel free to submit pull requests with your awesome ideas for improvement!

## Why Bitcoin Cache Machine Exists

If you're involved with Bitcoin, you will undoubtedly understand the importance of [running your own fully-validating bitcoin node](https://medium.com/@lopp/securing-your-financial-sovereignty-3af6fe834603) and operating your own IT infrastructure. Running a fully-validating node is easy enough--just download the software and run it on your home machine, but is that really enough to preserve your overall privacy? Did you configure it correctly? Are you also running a properly configured block explorer? Is your software up-to-date? Is your wallet software configured to consult your trusted full node? Has TOR for these services been tested properly? Are you routing your DNS queries over TOR? Are you backing up user critical data in real time?

There are tons of other areas where your privacy can be compromised if you're not careful. BCM is meant to handle these concerns by creating a privacy-centric software-defined home and office automation network. It's a data center for sovereign individuals.

Bitcoin Cache Machine dramatically lowers the barriers to deploying and operating your own bitcoin payment infrastructure. If you can provide the necessary hardware (CPU, memory, disk), a LAN segment, and an internet gateway, BCM can do much of the rest.

## Goals of Bitcoin Cache Machine

Below you will find some of the development goals for Bitcoin Cache Machine:

* Provide a self-contained, event-driven, software-defined network that deploys a fully operational Bitcoin and Lightning-related IT infrastructure.
* Run entirely on commodity x86_x64 hardware for home and small office settings. Run on bare-metal or in a self-hosted or cloud-based VM.
* Integrate exclusively free and open source software ([FOSS](https://en.wikipedia.org/wiki/Free_and_open-source_software))!
* Create a composable framework for deploying Bitcoin and Lightning-related components, databases, visualizations, web-interfaces, etc., allowing app developers to start with a fully-operational baseline data center.
* Automate the deployment and operation (e.g., backups, updates, vulnerability assessments, key and password management, etc.) of BCM deployments.
* Embrace hardware wallets for cryptographic  operations (trust boundaries, e.g., distinct lines of business accounting) where possible (e.g., Trezor-generated SSH keys or PGP certificates for authentication and encryption).
* Pre-configure all software to protect user's privacy (e.g., TOR for external communication, disk encryption, minimal attack surface, etc.). Use of TOR is default ya'll! If you want to compromise your security, go ahead but you're using an anti-pattern and compromising your security!
* Pursue [Global Consensus and Local Consensus Models](https://twitter.com/SarahJamieLewis/status/1016832509709914112) for core platform components, e.g., Bitcoin for global financial operations and [cwtch](https://openprivacy.ca/blog/2018/06/28/announcing-cwtch/) for asynchronous, multi-peer communications, etc..

## How to Run Bitcoin Cache Machine

`BCM SHOULD BE CONSIDERED FOR TESTING PURPOSES ONLY!!! IT HAS NOT UNDERGONE A FORMAL SECURITY EVALUATION!!!`

If you can run a modern Linux kernel and [LXD](https://linuxcontainers.org/lxd/), you can run BCM. BCM components run as background server-side processes only, so you'll usually want to have an always-on computer with a reliable Internet connection. You might consider putting this computer on a UPS (an el-cheapo suffices; BCM and its components all ASSUME that the computers are running on are commodity hardware!

 You can run BCM in a hardware-based VM, directly on bare-metal, or in "the cloud". Bitcoin Cache Machine components are deployed exclusively over the [LXD REST API](https://github.com/lxc/lxd/blob/master/doc/rest-api.md), so you can deploy BCM components to any LXD-capable endpoint! LXD is widely available on various free and open-source linux platforms. Stable BCM releases will usually follow the lastest Ubuntu LTS, which is 18.04 as of Oct 2018. This includes cloud images used by multipass, LXD base images (from the public "image:" server), and Docker base images from [http://dockerhub.com/](DockerHub).

Documentation for BCM and its components can be found in this source repository. Readme files in each directory tell you what you need to know about deploying the various infrastructure components at that level. For example, [the multipass README.md](./multipass/README.md) details the requirements for running BCM in a multipass-based VM and provides and directs the reader on what steps might be taken next and in which directory those steps might be found. 

But before you begin, clone this repository to your machine--the machine that will execute BCM shell (BASH) scripts. In the documentation, this machine is referred to as the `admin machine` since it manages sensitive information (passwords, certificates, etc.) and is required for administrative installations or changes.

# Getting Started

These instructions assume you're running Ubuntu Desktop 18.04. The instructions will be similar for other modern Linux distros.

The first step to getting started with Bitcoin Cache Machine is to clone the git repo to your `admin machine`. We will configure our local git client to download the BCM repository from github over TOR. This prevents github.com (i.e., Microsoft) from recording your real IP address.

```bash
sudo apt-get update
sudo apt-get install -y tor git
git config --global http.proxy socks5://localhost:9050
```

You can now clone the BCM repository to the `admin machine` over TOR:

```bash
mkdir -p ~/git/github/bcm
git clone https://github.com/BitcoinCacheMachine/BitcoinCacheMachine ~/git/github/bcm
cd ~/git/github/bcm/admin_machine
./setup.sh
```

Feel free to change the directory in which you store the BCM repository on your `admin_machine` (instead of ~/git/github/bcm). You may want to change your global git settings back to defaults so you won't download ALL git repos using TOR. Note that the BCM git repo specifically is configured to use TOR for git push/pull operations. Note that future BCM versions will be accessible using [IPFS](https://ipfs.io/).

```bash
git config --unset http.proxy
```

Visit the [./admin_machine/](./admin_machine/) directory to continue.

## Project Status

BCM is brand new and unstable. It is in a proof-of-concept stage. Don't put real bitcoin on it. Stable builds will be formally tagged, but we're not there yet. There are a lot of things that need to be done to it, especially in securing all the INTERFACES!!!

## How to contribute

Users wanting to contribute to the project may submit pull requests for review. A Keybase Team has been created for those wanting to discuss project ideas and coordinate. [Keybase Team for Bitcoin Cache Machine](https://keybase.io/team/btccachemachine)

You can also donate to the development of BCM by donating Bitcoin (BTC). For on-chain payments, use BIP47/PayNyms:

* on-chain - [Paynym Public Directory](https://paynym.is/+muddywaterfall4ed)
* on-chain - [BIP47](https://github.com/bitcoin/bips/blob/master/bip-0047.mediawiki) Payment Code: `PM8TJSpgDvY9aPVCHq1rQCYzvutYxf9GeK8ixhtZzeasXox3yDCskc8qkK2kgwK8rnN4AVVbUmPsMFGBdvuFfwo8JvuxNNW9quoHJhexD7dRutEi7Eon`
* off-chain - We will start accepting donations via Lightning network once Bitcoin Cache Machine reaches maturity!
  