#!/bin/sh
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
/usr/local/bin/trezor-gpg-agent \
-vv \
--pin-entry-binary=pinentry \
--passphrase-entry-binary=pinentry \
--cache-expiry-seconds=inf \
$*