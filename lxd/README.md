# lxd/

This folder contains the bulk of BCM. ALL scripts in this directory are applied against the active LXD remote endpoint, which can be viewed by running `lxc remote list` or `lxc remote get-default`.

## ./bcm_core/

This directory contains the main base data-center components including `gateway`, which host the following services:
