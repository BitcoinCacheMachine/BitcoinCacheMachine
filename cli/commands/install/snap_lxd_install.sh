#!/bin/bash

#set -Eeuo pipefail

BCM_TRUST_PASSWORD=

# remove any legacy lxd software and install install lxd via snap
if ! snap list | grep -q lxd; then
	sudo snap install lxd --edge
	sleep 10

	lxc config set core.https_address 0.0.0.0:8443

	if [[ ! -z $BCM_TRUST_PASSWORD ]]; then
		lxc config set core.trust_password "$BCM_TRUST_PASSWORD"
	fi
fi

# if the lxd groups doesn't exist, create it.
if ! grep -q lxd /etc/group; then
	sudo addgroup lxd
fi

if groups "$USER" | grep -q lxd; then
	sudo gpasswd -a "${USER}" lxd
	sudo snap restart lxd
fi
