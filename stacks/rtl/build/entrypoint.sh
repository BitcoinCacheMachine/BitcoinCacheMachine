#!/bin/bash

set -Eeu

if [ -f /secrets/RTL.conf ]; then
    echo "Copying /secrets/rtl.conf to /root/.rtl/rtl.conf"
    cp /secrets/rtl.conf /root/.rtl/rtl.conf
fi

# run rtl
node rtl
