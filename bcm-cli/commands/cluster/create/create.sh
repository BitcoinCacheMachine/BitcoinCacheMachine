#!/bin/bash

if [[ -d $BCM_PROJECT_DIR ]]; then
    echo "$BCM_PROJECT_DIR directory exists. Exiting."
else
    mkdir -p $BCM_PROJECT_DIR
fi
