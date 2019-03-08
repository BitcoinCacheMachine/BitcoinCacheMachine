# The BCM SDN Controller

This folder contains scripts related to the BCM SDN Controller. As mentioned, the SDN controller is usually a user-facing laptop or desktop running Ubuntu. The user interacts with this computer using his or her Trezor. The SDN controller manages one or more LXD clusters.

# How Bitcoin Cache Machine uses Trezor

BCM embrances the use of hardware wallets such as Trezor for all secure cryptographic functions. BCM currently support Trezor for 

* File encryption and file decryption (GPG)
* File signature creation and verification (GPG)
* SSH key generation and remote shell authentication
* GPG-signed commits (TODO GPG sign git tags)

You SHOULD enable passphrase encryption on your Trezor. You can do this using [wallet.trezor.io](wallet.trezor.io). BCM uses passphrase functionality on your hardware device to maintain separate keyspaces. For example, you can use passphrase functionality with BCM to keep all your development certificates separate from your production certificates, or you might use it to distinguish among your test, staging, and production workloads.
