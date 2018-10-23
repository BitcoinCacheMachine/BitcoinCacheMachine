
# <img src="./resources/images/bcmlogo_super_small.png" alt="Bitcoin Cache Machine Logo" style="float: left; margin-right: 20px;" /> Bitcoin Cache Machine

Bitcoin Cache Machine is open-source software that implements a self-hosted, privacy-centric, software-defined network. BCM is built entirely with free and open-source software and is meant primarily for home and small office use in line with the spirit of decentralization. Its broad purpose is to software-define your home, office, or cloud networks with resilient privacy-preserving Bitcoin-related payment and operating IT infrastructure.

## Project Status

> **IMPORTANT!**
> BCM is brand new and unstable. It is in a proof-of-concept stage. Don't put real bitcoin on it. Stable builds will be formally tagged once a stable proof-of-concept has been created.

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

Documentation for BCM and its components can be found in this repository. All documentation was written against Ubuntu 18.04, but should be applicable to most Debian-based distros.  `README.md` files in each directory tells you what you need to know about deploying the various infrastructure components at that level. The documentation is designed to read like a tutorial helping you understand how BCM is architected and how it can be used. It is recommended that the commands be manually typed into the terminal rather than using copy/paste. This helps improve your Linux [muscle memory](https://en.wikipedia.org/wiki/Muscle_memory) which is especially useful if you want to start developing on BCM.

## Getting Started

The first step to getting started with Bitcoin Cache Machine is to clone the git repo to your `dev machine`. You start start by installing [`tor`](https://www.torproject.org/) and [`git`](https://git-scm.com/downloads) on your machine then you configure your local `git` client to download the BCM repository from github using TOR. This prevents github.com (i.e., Microsoft) from recording your real IP address. (It might also be a good idea to use a TOR browser when browsing this repo directly on github.) Note that future BCM versions will be accessible using [IPFS](https://ipfs.io/).

```bash
sudo apt-get update
sudo apt-get install -y tor git
BCM_GITHUB_REPO_URL="https://github.com/BitcoinCacheMachine/BitcoinCacheMachine"
git config --global http.$BCM_GITHUB_REPO_URL.proxy socks5://localhost:9050
```

You can now clone the BCM repository to the `dev machine` over TOR:

```bash
mkdir -p ~/git/github/bcm
git clone $BCM_GITHUB_REPO_URL ~/git/github/bcm
cd ~/git/github/bcm/dev_machine
```

Feel free to change the directory in which you store the BCM repository on your `dev_machine` (instead of `~/git/github/bcm`).

Click the following link to continue with the tutorial: [./dev_machine/](./dev_machine/).

## How to contribute

Users wanting to contribute to the project may submit pull requests for review. A Keybase Team has been created for those wanting to discuss project ideas and coordinate. [Keybase Team for Bitcoin Cache Machine](https://keybase.io/team/btccachemachine)

You can also donate to the development of BCM by donating Bitcoin (BTC). For on-chain payments, use [BIP47](https://github.com/bitcoin/bips/blob/master/bip-0047.mediawiki):

* on-chain - [BCM Payment Code](bitcoin:PM8TJSpgDvY9aPVCHq1rQCYzvutYxf9GeK8ixhtZzeasXox3yDCskc8qkK2kgwK8rnN4AVVbUmPsMFGBdvuFfwo8JvuxNNW9quoHJhexD7dRutEi7Eon) Why BIP47 Payment Codes? Because sending to the same address every transaction is BAD FOR PRIVACY!

[<img src="./resources/images/bcm-payment-code.jpg" alt="BCM Payment Code" height="250" width="250">](bitcoin:PM8TJSpgDvY9aPVCHq1rQCYzvutYxf9GeK8ixhtZzeasXox3yDCskc8qkK2kgwK8rnN4AVVbUmPsMFGBdvuFfwo8JvuxNNW9quoHJhexD7dRutEi7Eon)

* off-chain - We will start accepting donations via Lightning network once Bitcoin Cache Machine becomes stable enough for us to confidently accept off-chain paymight via Lightning Network!