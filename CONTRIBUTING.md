# Collaborating

 A Keybase Team has been created for those wanting to discuss project ideas and coordinate. [Keybase Team for Bitcoin Cache Machine](https://keybase.io/team/btccachemachine)

# Contributing

## Getting Started

Sign up for a github.com account.

Fork the BitcoinCacheMachine repository to your account. Clone your forked repo to your machine then make some changes to your local repo. Feel free to make your changes on a branch of your making.

BCM is developed in Visual Studio Code by BCM's main author. Feel free to use any editor you want, just be sure to .gitignore any editor manifests.

## Linters

The authors of BCM works toward making BCM bash scripts [shellcheck](https://github.com/koalaman/shellcheck) compliant. Install shellcheck on your development machine by running `sudo apt-get install shellcheck` then add any editor extensions you might want, such as Bash Beautify.

## Pull Requests

When you are done, sign your staged changes (or optionally add the '--stage' flag) with your trezor using the following command. Because you're using the BCM CLI, all your git commits will be digitally signed using your Trezor-backed GPG certificates. Set GNUPGHOME in your shell to instruct BCM to use a different certificate directory.

```bash
bcm git commit --message="Update message." --push
```

Next, create a [pull request](https://github.com/BitcoinCacheMachine/BitcoinCacheMachine/pulls) into the main BitcoinCacheMachine repo master branch.

# Review Board

TODO - Define change control / pull request review process.

# Credits

This guide is [based on the excellent repository](https://git.openprivacy.ca/cwtch.im/cwtch/raw/master/CONTRIBUTING.md) at the [OpenPrivacy](https://openprivacy.ca/) group.
