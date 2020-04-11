#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# this script copies the contents of ./jekyll_site/_site and sends it to BCM_ZERONET_PATH
# which must be defined in your environment. Only one person controls http://127.0.0.1:43110/1KqjsEPJ9cmbnHop5VneDG4ws9i9ufYbch/

# first let's make sure zeronet is turned OFF so we can update folder permissions
# and copy file
if [[ -z $BCM_ZERONET_PATH ]]; then
    echo "ERROR: BCM_ZERONET_PATH must be defined."
    exit
fi

if [[ ! -d $BCM_ZERONET_PATH ]]; then
    echo "ERROR: BCM_ZERONET_PATH must exist."
    exit
fi

# first, let's stop zeronet if its running.
bash -c ./zeronet/stop_zeronet.sh

# let's build the website using jekyll.
bash -c ./build_site.sh

# move resulting files to the BCM_ZERONET_PATH directory
sudo cp -a ./jekyll_site/_site/* "$BCM_ZERONET_PATH/"
sudo chown -R root:root "$BCM_ZERONET_PATH"

# now run zeronet so it'll uptake the site contents.
bash -c ./zeronet/run_zeronet.sh
