#!/bin/bash

if ! snap list | grep -q lxd; then
	sudo snap remove lxd
fi
