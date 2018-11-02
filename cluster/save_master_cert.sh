#!/bin/bash

# this script saves the certificate from LXC INFO
# and is used to populate member preseed files.


# since it's the master, let's grab the certificate so we can use it in subsequent lxd_preseed files.
CERT_FILE=$LXD_DIR/lxd.cert
if [[ ! -f $CERT_FILE ]]; then
  mkdir -p $LXD_DIR
  # get the cluster master certificate using LXC.
  lxc info | awk '/    -----BEGIN CERTIFICATE-----/{p=1}p' | sed '1,/    -----END CERTIFICATE-----/!d' | sed "s/^[ \t]*//" -i $CERT_FILE
fi
