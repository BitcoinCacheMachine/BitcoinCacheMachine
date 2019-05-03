# Contributing

## Getting Started

Sign up for a github.com account.

Get the code by following the instructions in "Getting Started"

Make a development branch to do your work

    git checkout -b branch-name

BCM is developed in Visual Studio Code by BCM's main authors. Feel free to use any editor you want, just be sure to .gitignore any editor manifests.

## Linters

The authors of BCM ensures that BCM bash scripts are shellcheck compliant (with the exception of explicitly ignored errors, see [.vscode/settings.json](.vscode/settings.json)). Install shellcheck `sudo apt-get install shellcheck` then add any editor extensions you might want, such as Bash Beautify.

## Pull Requests

When you are done, rebase squash any multiple commits you have into one

    git rebase -i master

Run BCM's test suite (TODO):

    ./tests/tests.sh (TODO)

push your branch (-f for *force* in the case you've rebased and squashed)

    git push origin branch-name -f
    
create a [pull request](https://github.com/BitcoinCacheMachine/BitcoinCacheMachine/projects)

If you have fixes, you can amend them to the current commit rather than a new one with

    git commit --amend
    git push -f

## Review Board

TODO - Define change control / pull request review process.

## Credits

This guide is [based on the excellent repository](https://git.openprivacy.ca/cwtch.im/cwtch/raw/master/CONTRIBUTING.md) at the [OpenPrivacy](https://openprivacy.ca/) group.