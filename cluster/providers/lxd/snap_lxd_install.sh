#!/bin/bash

# remove any legacy lxd software and install install lxd via snap
if ! snap list | grep -q lxd; then

	# if the lxd groups doesn't exist, create it.
	if ! grep -q lxd </etc/group; then
		sudo addgroup --system lxd
	fi

	# add the current user to the lxd group if necessary
	if ! groups "$(whoami)" | grep -q lxd; then
		sudo adduser "$(whoami)" lxd
		newgrp lxd -
	fi

	sudo snap install lxd --stable

	# usually good to wait before exiting; other tools may try to use the tool
	# before its initiailzed.
	sleep 10
fi
