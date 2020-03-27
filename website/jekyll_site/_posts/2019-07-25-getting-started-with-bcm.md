---
layout: post
title:  Getting Started with Bitcoin Cache Machine
subtitle: Learn the basics of BCM and how to get it on your machine!
date:   2019-07-20 17:00:00 -0500
tags: [documentation, learning, slides]
author: farscapian
---

It's been a while since I added any posts to this website! To make up for my slack, I'm making a commitment to produce a blog post every couple weeks to demonstrate some of the neat things Bitcoin Cache Machine is capable of! Stay tuned to this website and Twitter.

In this article, I describe some of the basics of Bitcoin Cache Machine (BCM). This includes how to get it, how and when to use it, and what some of the basic functionalities are. I'll go into greater detail in later posts and show you how you can use all the features provided by BCM.

BCM is just a bunch of Bash scripts you download to your workstation (laptop/desktop). BCM allows you to deploy Bitcoin-related software to your local computer or to one or more remote machines.BCM integrates all software components so you can work in a trust-minimized manner! You no longer need to rely on untrusted third parties! Ditch those custodial services that can steal or censor your Bitcoin transaction. Say goodbye to third-party block explorers that surveil and log your every query! It's the way Bitcoin was meant to be used--without reliance on anybody but yourself!

All BCM components are deployed such that services (e.g., bitcoin RPC, bitcoind P2P, clightning RPC, etc) can be securly accessed from your local network secured using a Wireguard VPN. All services are also exposed over Tor onion services when operating from the Internet. Because BCM uses TOR, there's never any need to open firewall ports!

The scripts provided in the BCM repository provide everything you need to deploy BCM components, whether it's a Bitcoin Core full node, clightning node, Spark web application to manage that node, or a desktop application like Electrum wallet. All components are configured to consult your full node in a trust minimized manner. BCM also includes scripts that allow you to perform manual backup backup and restoration of critical data. BCM is built for privacy: all components are configured to use TOR for outbound communication when possible. You need to have a Trezor-T hardware wallet in order to use BCM. 

## Download BCM to your computer

INSERT GETTING STARTED INSTRUCTIONS

## Initialize BCM; download necessary software

BCM scripts download and install pre-requisites. Software that BCM installs include 

## 