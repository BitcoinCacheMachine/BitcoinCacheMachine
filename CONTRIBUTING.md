# Contributing

## Getting Started

Sign up for a github.com account.

Fork the BitcoinCacheMachine repository to your account. Clone your forked repo to your machine then make some changes to your local repo. Feel free to make your changes on a branch of your making.

BCM is developed in Visual Studio Code by BCM's main authors. Feel free to use any editor you want, just be sure to .gitignore any editor manifests.

## Linters

The authors of BCM works toward making BCM bash scripts [shellcheck](https://github.com/koalaman/shellcheck) compliant. Install shellcheck on your development machine by running `sudo apt-get install shellcheck` then add any editor extensions you might want, such as [Bash Beautify]().

## Pull Requests

When you are done, sign your staged changes with your trezor using the following command:

    bcm git commit --message="Git commit message."

push your changes to your forked repo.

    git push origin
    
Next, create a [pull request](https://github.com/BitcoinCacheMachine/BitcoinCacheMachine/projects) into the BitcoinCacheMachine repo master branch.

If you have fixes, you can amend them to the current commit rather than a new one with

    git commit --amend
    git push -f

## Review Board

TODO - Define change control / pull request review process.

## Credits

This guide is [based on the excellent repository](https://git.openprivacy.ca/cwtch.im/cwtch/raw/master/CONTRIBUTING.md) at the [OpenPrivacy](https://openprivacy.ca/) group.
