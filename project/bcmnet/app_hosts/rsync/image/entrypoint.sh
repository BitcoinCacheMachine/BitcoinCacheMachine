#!/bin/bash
set -e

exec /usr/sbin/sshd -D &

if [ -f /etc/rsyncd.conf ]; then
    exec /usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf "$@"
else
    exec "$@"
fi