# How Bitcoin Cache Machine uses Trezor

BCM embrances the use of hardware wallets such as Trezor for all secure cryptographic functions. BCM uses (PLANNED) Trezor for file encryption and decryption, signature creation and verification (all using GPG). SSH authentication for remote administrative login is planned to be supported. GPG-signed commits and tags are also planned.

First, you need to make sure that your Trezor supports passphrases. You can do this using [wallet.trezor.io](wallet.trezor.io). BCM uses passphrase functionality on your hardware device to keep certificate issuance segregated for your various BCM projects that you might deploy. You can use passphrase functionality with BCM to keep all your development certificates separate from your production certificates, for example. Using passphrases is also good for security because they are meant to be REMEMBERED.

# Getting started

Run the following script at the command line:

```bash
./up_trezor.sh -n bcm -e bob@DEV_MACHINE
```

The -n parameter is the name of your new BCM project. This name MUST be unique under the `$BCM_RUNTIME_DIR/projects` directory. The `-e` parameter is used as the user identity (uid) in the GPG certificates. The convention that is RECOMMENDED is the `<username>` be something you personally identify with. The `host` parameter (`cluster1` in the example above) MUST be set to the cluster name that the project is being deployed to. In other words, `<host>` MUST have a folder corresponding to `$BCM_RUNTIME_DIR/clusters/<host>`. If you're following the tutorial, the `../up_dev_machine.sh` script created this for you already.

`./up_trezor.sh` starts by doing input validation and ensuring all the parameters are valid. It then loads BCM environment variables, then checks to ensure a Trezor USB device is plugged in. It's important that you enter your PIN number PRIOR to running `./up_trezor.sh` otherwise the USB device won't be discovered.

# The technicals

The starting point for this folder is `./Dockerfile`. This Dockerfile shows how to create a docker container image that contains ALL the necessary software dependencies for using a trezor for SSH, GPG, and GIT operations.