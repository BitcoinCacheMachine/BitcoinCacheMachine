#!/bin/bash

set -Eeuox pipefail

mkdir -p /tmp/bcm_enc
mkdir -p /tmp/bcm

encfs /tmp/bcm_enc /tmp/bcm -i=10 --extpass="apg -n 1 -m 30 -M CN" >> /dev/null
