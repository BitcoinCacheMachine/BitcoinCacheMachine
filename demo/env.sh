#!/bin/bash

set -eu
cd "$(dirname "$0")"

# this file demonstrates the CLI steps that are necessary to arrive at
# an example BCM stack. This script SHOULD be run AFTER access to the 
# bcm command line utility is verified. You're probably in good shape
# if you can type 'bcm' and have help show up.

export BCM_DEBUG=1
export BCM_CLUSTER_NAME="$(hostname)"
export BCM_PROJECT_NAME="BCMSparkStack"
export BCM_CERT_USERNAME="$(whoami)"
export BCM_CLUSTER_USERNAME="$(whoami)"
export BCM_PROJECT_USERNAME="$(whoami)"
export BCM_CERT_HOSTNAME="$(hostname)"
