# How Bitcoin Cache Machine uses Trezor

BCM embrances the use of hardware wallets such as Trezor for all secure cryptographic functions. BCM currently support Trezor for 

* File encryption and file decryption, 
* Create file signatures and verificat file signatures (all using GPG)
* SSH key generation and remote shell authentication
* GPG-signed commits (tags planned).

You SHOULD enable passphrase encryption on your Trezor. You can do this using [wallet.trezor.io](wallet.trezor.io). BCM uses passphrase functionality on your hardware device to achieve separate keyspaces (you will get all GPG, SSH key pairs, etc., for each BIP32 path). You can use passphrase functionality with BCM to keep all your development certificates separate from your production certificates, for example, or for distinguishing between test, staging, and production workloads.
