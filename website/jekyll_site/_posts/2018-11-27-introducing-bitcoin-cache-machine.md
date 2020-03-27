---
layout: post
title:  Introducing Bitcoin Cache Machine
author: farscapian
subtitle: a privacy-preserving Software-defined Data Center
tags: [bitcoin, lightning, software-defined-network]
---

Bitcoin Cache Machine is open-source software that implements a self-hosted, privacy-preserving, software-defined network. BCM is built entirely with free and open-source software and is meant primarily for home and small office use in line with the spirit of decentralization. Its broad purpose is to software-define your home or office network with resilient privacy-preserving Bitcoin-related payment and operating IT infrastructure.

## Status

Bitcoin Cache Machine is still very new and recommended for testing purposes only. It is far from feature complete and has NOT undergone a formal security evaluation. We’re hoping to increase the community of open-source developers that work on Bitcoin Cache Machine. If you would like to participate in the development of Bitcoin Cache Machine, take a look at the project on Github or consider coordinating with the existing developers in the Keybase Team.

## Why is Bitcoin Cache Machine is needed

Before we get into the weeds of what Bitcoin Cache Machine is and what it does, let’s step back and understand WHY Bitcoin Cache Machine is needed.

Over time, our personal information—our address, family members, favorite childhood pet, elementary school, our Socialist Security Numbers—all the informational tidbits that online services have asked us for over the years, gets hacked. It’s easy to see why. Companies like Experian work each day to collect our sensitive personal information and store it in centralized databases–veritable honeypots for would-be hackers. A single successful hack makes it far more likely that financial fraud will be committed in your name. Fundamentally, this is because the existing (legacy) financial system depends on personal information to establish trust relationships.

The answer to this craziness is to not disclose our personal information to untrusted third parties in the first place. This is unavoidable to an extent when operating in the legacy financial system. Fortunately we have Bitcoin–a monetary system that operates outside of the existing broken system. In Bitcoin, trust is (partially) established by proving knowledge of private information; it simply doesn’t rely on readily-available personal information. By using Bitcoin, we can reduce the impact of financial fraud being committed in our name.

Using Bitcoin is a great first step, but there are a myriad of other ways your personal information—or metadata—can be disclosed to third parties. Many web wallets, for example, consult hosted Bitcoin nodes or link to public block explorers, or download transaction history and price data from public servers. Without adequate protection, those hosting these public services can glean and store informational tid-bits, and given enough information, e.g., your public IP address, bitcoin transactions, XPUBs, etc., third parties can determine who you are or how much or WHICH bitcoins are yours! Not great for your privacy! And what about your communication services? Services like Signal help by protecting the content of your messages, but do little to prevent adversaries from compromising your communication metadata.

To prevent our personal data from being disclosed, we MUST run our own IT infrastructure. Not an easy task for most people.

## Introducing Bitcoin Cache Machine

Bitcoin Cache Machine is a software-defined data center capable of automating the deployment and operation of your own privacy-preserving IT infrastructure. It allows you to run a fully-operational data center in your home or office. It’s a platform for bitcoin and lightning-related development. If you have an old computer, you can install BCM on it and software-define your network while simultaneously on-boarding yourself onto the Bitcoin and Lightning economy.

BCM deploys the latest Bitcoin Core full node so you can start participating in the Bitcoin economy and have full assurance of the underlying financial system. You can deploy BCM with one or more Lightning daemons, web wallet interfaces, databases, etc., or you can package up your own custom software to run against a BCM software stack! BCM is designed to be composable, so you can piece together the components you need like legos! All deployed components are pre-configured to emit logging information to nearby Apache Kafka-based messaging stacks. Kafka provides distributed messaging and event and source logging. Event processing is expected to Kafka Streams 5.0 KSQL API and toolset. One of the development goals of BCM is to provide event schema classification and evolution (via Apache Avro) for all supported components (e.g., bitcoind, lightningd, etc.) which will allow workflow developers to program against a common and structured data model.

BCM isn’t just about using Bitcoin, it’s about protecting your overall privacy. Whenever possible, BCM uses TOR for outbound client/server and peer-to-peer (e.g., bitcoind, lightningd, etc.) communication. You have the option of exposing various RPC interfaces as authenticated onion sites which is great for mobile apps requiring access to your hosted RPC interfaces. BCM thus requires outbound TCP 9050 to host services on the Internet; fiddling with external firewalls is often unnecessary.

You can deploy as many BCM instances as you want, you just will need to bring disk, memory, compute, and an internet connection! Key management for your software-defined data center will use hardware wallets for secure cryptographic operations; hardware wallets will function as the trusted Root CA for all client and server certificates deployed within your data center. Each data center/trust boundary you create is operated by a distinct BIP32 path!

BCM is deployed entirely against the LXD REST API. This means you can run BCM or any of its components on ANY networked computer (or your local machine) capable of running LXD. As it happens, getting a modern Linux distribution ready to host BCM is a snap. The BCM github repo includes shell scripts and cloud-init files that prepare your computer for LXD commands. Getting started with BCM is quick and simple and free since it’s built entirely using open source!

## Conclusion

BCM dramatically lowers the barriers to deploying and operating your own privacy-preserving bitcoin payment infrastructure. This network and its components deploy in a fully automated way and run on commodity x86_64, so it’s likely you can start testing it today! You just need to provide CPU, memory, disk, a modern Linux kernel with LXD installed, and an Internet connection! Deploy any combination of BCM components to create the data center that suits your particular needs!
