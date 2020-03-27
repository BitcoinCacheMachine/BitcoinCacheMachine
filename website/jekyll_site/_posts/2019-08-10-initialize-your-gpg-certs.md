---
layout: post
title:  Use BCM with your Trezor
subtitle: Initialize your Trezor GPG certificates, make git commits and tags, and login to a remote machine using SSH.
date:   2019-07-20 17:00:00 -0500
tags: [documentation, learning, slides]
author: farscapian
---

## How BCM uses your Trezor

Most cryptographic operations in BCM use Trezor-backed GPG certificates. We recommend you buy a dedicated Trezor-T device for your BCM activities.

## Use 'bcm init' to create new GPG certificates and Password Store

When you first start using BCM, it will detect whether your have initilzed your GPG and password stores. If `~/.gnupg/trezor` doesn't yet exist, you will be prompted to create new GPG certificates. Be sure you have your Trezor handy! Of course, you can always generate them manually by running `bcm init` at the CLI.

When generating new certificates, you will be asked for the Certificate Title, username, and domain name. This defines the title of your certificate. For example, if your name is `Satoshi Natamoto`, username is `satoshi`, and your domain is `bitcoin.org`, your certificate will look like.

```
Satoshi Nakamoto <satoshi@bitcoin.org>
```

After the prompts, BCM scripts communicate with your Trezor to generate them. You can generate the certificates at the BIP32 root of the device, or you're welcom

## Use 'bcm git' command to create signed git commit and git tags

## Use 'bcm ssh' to perform SSH authentication with remote machines

## Use 'bcm file' commands to encrypt and decrypt files

## Use 'bcm file' commands to create and verify file signatures

## Use 'bcm pass' commands to create and manage passwords locally