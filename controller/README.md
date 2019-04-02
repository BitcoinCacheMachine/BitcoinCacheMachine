# The BCM SDN Controller

This folder contains scripts related to the BCM SDN Controller. As mentioned, the SDN controller is usually a user-facing laptop or desktop running Ubuntu. The user interacts with this computer using his or her Trezor. The SDN controller manages one or more LXD clusters.

# How Bitcoin Cache Machine uses Trezor

BCM embrances the use of hardware wallets such as Trezor for all secure cryptographic functions. BCM currently support Trezor for 

* File encryption and file decryption (GPG)
* File signature creation and verification (GPG)
* SSH key generation and remote shell authentication
* GPG-signed commits (TODO GPG sign git tags)
* And obviously, Bitcoin transactions.

You SHOULD enable passphrase encryption on your Trezor. You can do this using [wallet.trezor.io](wallet.trezor.io). BCM uses passphrase functionality on your hardware device to maintain separate keyspaces. For example, you can use passphrase functionality with BCM to keep all your development certificates separate from your production certificates, or you might use it to maintain keyspace separation among your test, staging, and production workloads.

# Dockerfile

The `./Dockerfile` defines the BCM image bcm-trezor:$BCM_VERSION. This image is used exclusively within the docker daemon on the SDN controller. This image is NOT used within BCM back-end workloads. It is designed for interaction with the user via interactive shell scripts and USB/Trezor mounting for interaction with Trezor devices.  `build.sh` is responsible for building the BCM controller docker image `bcm-trezor`. You can run `docker images` to view images on your machine. BCM-managed images are prepended with `bcm-`.

## Container Scripts

The directory `./container_scripts/*` are all pushed to the directory `/bcm` within the `bcm-trezor` image. Various BCM scripts invoke the shell scripts in `/bcm` to enact functionality, for example, signing a git repository.
