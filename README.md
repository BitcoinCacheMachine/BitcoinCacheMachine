
# Bitcoin Cache Machine

Bitcoin Cache Machine is open-source software that allows you to create and manage one or more Bitcoin-focused privacy-preserving personal payment systems (perfect for long-term HODLers). BCM scripts allow you to quickly deploy a purely software-defined bitcoin payment stack to your local Ubuntu machine, or any Ubuntu-based SSH endpoint (e.g., SSH over LAN, SSH over Tor onion). BCM is built entirely with free and open-source software and is meant primarily for long-term Bitcoin HODLrs that want to run their own Bitcoin node infrastructure along with privacy-preserving technologies such as JoinMarket for on-chain UTXO management, and c-Lightning for access to Bitcoin's high-speed and low-free payment network, Lightning.

## Project Status

**IMPORTANT!** BCM is brand new and unstable, only use testnet coins! Builds will be formally tagged using the public key [PGP.pub](./PGP.pub) once a stable proof-of-concept has been created. The master branch represents the most up-to-date stable, and tested, version of BCM. Main development occurs on this fork [farscapian/BitcoinCacheMachine](https://github.com/farscapian/BitcoinCacheMachine).

BCM HAS NOT undergone formal security evaluation and should be considered for TESTING PURPOSES ONLY.

```YOU ASSUME ALL RISK IN USING THIS SOFTWARE!!!```

## Why Bitcoin Cache Machine Exists

If you're involved with Bitcoin or care about your privacy, you will undoubtedly understand the importance of [running your own node](https://www.youtube.com/watch?v=UYUfXWlAleA). Running a fully-validating node is easy enough--just download the software and run it on your home machine, but is that really enough to preserve your overall privacy? Did you configure it correctly? Are you also running a properly configured block explorer? Is your software up-to-date? Are you ensuring that all your UTXOs are unlinked from your identity and all your services using Tor?

There are many areas where your privacy can be compromised if you're not careful. BCM is meant to handle many of these concerns by creating a software-defined data center at your home or office that's pre-configured to protect your overall privacy. If you can provide the necessary hardware (CPU, memory, disk), a LAN segment, and an internet gateway, BCM can do much of the rest.

For more information about the motivations behind Bitcoin Cache Machine, visit the [public website](https://www.bitcoincachemachine.org/2018/11/27/introducing-bitcoin-cache-machine/).

## Development Goals

Here are some of the development goals for Bitcoin Cache Machine:

* Provide a self-contained, distributed, event-driven, software-defined data center that focuses on operational Bitcoin and Lightning-related IT infrastructure.
* Enable small-to-medium-sized scalability by adding commodity x86_x64 hardware for home and small office settings.
* Allow for multi-tenancy; support multiple users on the same hardware.
* Integrate free and open source software ([FOSS](https://en.wikipedia.org/wiki/Free_and_open-source_software))!
* Create a composable framework for deploying Bitcoin and Lightning-related components, databases, visualizations, web-interfaces, etc., allowing app developers to start with a fully-operational baseline data center.
* Automate the deployment and operation (e.g., backups, updates, vulnerability assessments, key and password management, etc.) of BCM deployments.
* Require hardware wallets for cryptographic operations (PGP, SSH, and Bitcoin transactions).
* Configure all software to protect user's privacy (e.g., TOR for external communication, disk encryption, minimal attack surface, etc.).

## What is needed to Run Bitcoin Cache Machine

You need an x86 machine capable of running a Debian-based Linux. At least 2 Network Iterfaces are required (wireless works, not recommended). At a minimum, you need AT LEAST ONE SSD. Better to have two configured in a BTRFS pool. For better disaster recovery, you should have AT LEAST ONE SD card attached as well. Again, if you have TWO configured in a BTRFS pool, even better. Finally, you can add ONE OR MORE spinning HDDs all configured in a BTRFS pool for capacity. See the public website for instructions on configuring the various tiers of storage used by BCM.

## Getting Started

Run the following commands to run the BCM `git_bcm.sh` script. If you want to collaborate on BCM, first fork it to your github account then run the commands below, updating the `BITHUB_REPO` environment variable with your repo.

```bash
# download the BCM init script; VERIFY CONTENTS!
GITHUB_REPO="BitcoinCacheMachine/BitcoinCacheMachine"
wget "https://raw.githubusercontent.com/$GITHUB_REPO/master/get.sh"

# WARNING: YOU SHOULD ALWAYS DO YOUR DUE DILLEGENCE BEFORE RUNNING
# A SCRIPT ON YOUR COMPUTER. YOU SHOULD NOT TRUST THIS SOFTWARE UNLESS
# YOU HAVE VIEWED AND AUDITED ITS CODE PERSONALLY!

# make the script executable then run it
chmod 0744 ./get.sh
sudo bash -c "./get.sh --repo=$GITHUB_REPO"
```

The script above install the latest tor proxy, the pulls the BCM git clones the repo using TOR transport. Now that you have the code (in the `~/bcm` directory), you can decide how you want to deploy BCM. You can deploy it locally on bare-metal (best performance, good for single-user use) or in Type-1 VMs. Type 1 VMs are useful if you want to run multiple BCM instances on shared hardware (e.g., a full node for each family member). Finally, you can use BCM to deploy server-side infrastructure via remote SSH service (local network or authenticated onion service).

After you have the BCM scripts, run the installer script. This installs necessary software as well as makes the `bcm` command available to the user's shell environment. Running just `bcm` will give you a help menu.

```bash
bash -c ./install.sh
```

You may want to log out for your group membership to update. 

Next, decide how you want to run BCM:

. If you want to run BCM in Type-1 vms with hardware-enforced separation, use `bcm deploy`. Export BCM_VM_NAME to deploy more Type 1 VMs.
  If you want to run BCM directly on your localhost, run the deployment script `bcm deploy --localhost`.
  If you want to deploy BCM to a remote SSH endpoint, export BCM_SSH_HOSTNAME in your environment, and local `bcm` commands will be executed against the remote SSH host.

## Documentation

The best documentation can be found using the CLI `--help` menus. You can also consult the README.md files in the major directories of this repo. Consult [CLI README](./commands/README.md) for notes on how to use the BCM CLI.

## How to contribute

See [How to Contribute](./CONTRIBUTING.md) for additional details on contributing to the overall project. We need testers software testers, documentation, and of course BASH Developers capable of programming LXD and Docker, among many other mostly back-end software.

## Issues

Currently BCM tracks "issues" with the software using `# TODO` stanzas in the code itself. Once BCM becomes stable enough, public accounting of issues will be allowed. In the meantime, collaborate with developers using the Keybase group.