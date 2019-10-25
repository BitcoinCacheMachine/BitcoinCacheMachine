#!/bin/bash

if multipass list | grep -q bcm; then
    multipass stop bcm
    multipass delete bcm
    multipass purge
else
    echo "INFO: the multipass vm 'bcm' was not found."
fi
