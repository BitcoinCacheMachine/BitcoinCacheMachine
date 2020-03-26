#!/bin/bash

if [[ -z $BCM_VM_NAME ]]; then
    echo "ERROR: BCM_VM_NAME IS not defined. Please set your environment ~/.bashrc."
    exit
fi
if multipass list | grep -q "$BCM_VM_NAME"; then
    multipass umount "$BCM_VM_NAME":
    multipass stop "$BCM_VM_NAME"
    multipass delete "$BCM_VM_NAME"
    multipass purge
else
    echo "INFO: the multipass vm '$BCM_VM_NAME' was not found."
fi
