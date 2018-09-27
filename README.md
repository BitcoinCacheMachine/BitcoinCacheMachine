
# <img src="./resources/bcmlogo_super_small.png" alt="Bitcoin Cache Machine Logo" style="float: left; margin-right: 20px;" /> Bitcoin Cache Machine

Bitcoin Cache Machine (BCM) is an event-driven, software-defined data center created for developers, individuals, and small businesses wanting to own and operate their own bitcoin-related payment infrastructure. It's a Personal Financial Operating System (PFOS) based entirely on the ONLY secure blockchain--Bitcoin (as determined by the fabulous open-source implementation we call Bitcoin Core)! It's a platform for your Bitcoin-based business.

**IMPORTANT! BCM is intended for testing purposes ONLY! It is very new and under heavy development by a single author and HAS NOT undergone a formal security evaluation and it is VERY likely to have vulnerabilities. USE AT YOUR OWN RISK!!!**

BCM deploys in a fully automated way and runs on bare-metal Linux, in a VM, on-premise (preferred), or in the cloud (i.e., on someone elses computer!). It's consists entirely of open-source software. BCM is MIT licensed, so fork away and feel free to submit pull requests with your awesome ideas for improvement!

## Why Bitcoin Cache Machine Exists

If you're involved with Bitcoin, you will undoubtedly understand the importance of [running your own fully-validating bitcoin node](https://medium.com/@lopp/securing-your-financial-sovereignty-3af6fe834603) and operating your own IT infrastructure. Running a fully-validating node is easy enough--just download the software and run it on your home machine, but is that really enough to preserve your overall privacy? Did you configure it correctly? Are you also running a properly configured block explorer? Is your software up-to-date? Is your wallet software configured to consult your trusted full node? Has TOR for these services been tested properly? Are you routing your DNS queries over TOR? Are you backing up user critical data in real time?

There are tons of other areas where your privacy can be compromised if you're not careful. BCM is meant to handle these concerns by creating a privacy-centric software-defined home and office automation network. It's a self-hosted software-defined data center for Bitcoin maximalists.

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

If you can run a modern Linux kernel and [LXD](https://linuxcontainers.org/lxd/), you can run BCM. You can run BCM in a hardware-based VM, directly on bare-metal, or in "the cloud". Bitcoin Cache Machine components are deployed exclusively over the [LXD REST API](https://github.com/lxc/lxd/blob/master/doc/rest-api.md), so you can deploy BCM to any LXD-capable endpoint! LXD is widely available on various free and open-source linux platforms. BCM has been developed and primarily tested using Ubuntu 18.04.

Documentation can be found in each directory and in the wiki. Readme files in each directory tell you what you need to know about deploying the various infrastructure components at that level. [README.md](./multipass/README.md) details the requirements for running BCM in a multipass-based VM and provides simple instructions for getting started. But before you begin, clone this repository to your machine--the machine that will execute BCM shell (BASH) scripts. In the documentation, this machine is referred to as the `admin machine` since it manages sensitive information (passwords, certificates, etc.) and is required for administrative installations or changes.

# Getting Started

Clone the BCM reference implementation on to the `admin machine` and cd into the root of the repository. Open a terminal then run the following commands to get started:

```bash
mkdir -p ~/git/github/bcm
git clone https://github.com/BitcoinCacheMachine/BitcoinCacheMachine ~/git/github/bcm
cd ~/git/github/bcm
./setup.sh
```

`./setup.sh` prepares the `admin machine` for using BCM scripts. It also installs LXD on the `admin machine` so you can deploy BCM scripts locally for testing. `./setup.sh` creates the directory ~/.bcm, which is where BCM scripts store and manage sensitive deployment options and runtime files. Click [here](./setup_README.md) for more information.

Decide where you want to run your BCM workload. You can deploy BCM to the `admin machine` for quick and convenient testing. You can consider running BCM in a [multipass-based VM](./multipass/) or in a [cloud provider via cloud-init](./cloud_providers/). `multipass` VMs use lower-level hardware-based virtualization which provide additional security guarantees. In the end, all you need to run BCM component is a LXD endpoint configured and controllable by your `admin machine`. Use the `lxc remote list`, `lxc remote get-default` and related commands.

Once you have a properly configured LXD endpoint, delve into the [./lxd/](./lxd/) directory. This is where BCM data center components reside. You'll spend a lot of time in this directory. Scripts in this directory execute against the currently configured LXD remote. By running BASH scripts on the `admin machine`, you can deploy software-defined components to the target LXD endpoint.

## Project Status

BCM is brand new and unstable. It is in a proof-of-concept stage. Don't put real bitcoin on it. Stable builds will be formally tagged, but we're not there yet. There are a lot of things that need to be done to it, especially in securing all the INTERFACES!!!

## How to contribute

Users wanting to contribute to the project may submit pull requests for review. A Keybase Team has been created for those wanting to discuss project ideas and coordinate.

[Keybase Team for Bitcoin Cache Machine](https://keybase.io/team/btccachemachine)