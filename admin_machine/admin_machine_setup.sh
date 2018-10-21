#!/usr/bin/env bash

# This script iniitalizes the management computer that is executing 
# BCM-related LXD and multipass scripts against (local) or remote LXD
# endpoints.

# quit if there's an error
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# first a common problem with new installations is that git itsn't fully configured.
# let's test for this condition and quit if necessary.
if [[ -z $(git config --get --global user.name) ]]; then
  echo "You need to configure the git user.name configuration parameter so we can make commits. Run the following command:"
  echo "    git config --global user.name bubba"
  exit
fi

# same for email address
if [[ -z $(git config --get --global user.email) ]]; then
  echo "You need to configure the git email parameter so we can make commits. Run the following command:"
  echo "    git config --global user.email bubba@nowhere.com"
  exit
fi

cd ..
if [[ $(git config --get http.proxy) != "socks5://localhost:9050" ]]; then
  git config http.proxy socks5://localhost:9050
fi
cd "$(dirname "$0")"

# get the current directory where this script is so we can reference it later, namely in .bashrc
# file on the admin machine.
echo "Setting BCM_LOCAL_GIT_REPO environment variable in current shell to '$(dirname "$(pwd)")'"
export BCM_LOCAL_GIT_REPO="$(dirname "$(pwd)")"


# reset to current dir
cd "$(dirname "$0")"

# TODO implemented encfs on ~/.bcm
# if ~/.bcm doesn't exist, create it
if [ ! -d ~/.bcm ]; then
  echo "Creating Bitcoin Cache Machine config directory at ~/.bcm"
  mkdir -p ~/.bcm
  git init ~/.bcm/
  cd ~/.bcm
fi

# if ~/.bcm/clusters doesn't exist, create it.
if [ ! -d ~/.bcm/clusters ]; then
  echo "Creating BCM clusters directory at ~/.bcm/clusters"
  mkdir -p ~/.bcm/clusters
fi

# certificates - we store root certificates here
if [ ! -d ~/.bcm/certs ]; then
  echo "Creating BCM certs directory at ~/.bcm/certs"
  mkdir -p ~/.bcm/certs

  # TODO we will change the self-signed root certificate to use Trezor 
  # generate the private key for the root certificate
  # Docs: this is essentially the root-of-trust for your software-defined datacenter.
  # I'll eventually source this key on a bitcoin hardware device using usb-based docker image.
  openssl genrsa -out ~/.bcm/certs/rootca.key 4096

  # We wil self-sign this certificate
  # this is what we will install on all BCM LXC hosts as the root certificate to trust; any cert signed by rootca.key will be trusted
  # and will be used as trust/authentication boundary, i.e., one self-signed Root CA per BIP32 path.
  openssl req -x509 -subj "/C=US/ST=BCM/L=INTERNET/O=BCM/CN=BCM ROOT CA" -new -nodes -key ~/.bcm/certs/rootca.key -sha256 -days 365 -out ~/.bcm/certs/rootca.cert

  git add *
  git commit -am "Added ~/.bcm/certs/rootca.key and rootca.cert"
else
  echo "BCM certs directory exists at ~/.bcm/certs"
fi

BCM_BASHRC_FLAG='### Start BCM'

if grep -Fxq "$BCM_BASHRC_FLAG" ~/.bashrc
then
  # code if found
  echo "BCM flag discovered in ~/.bashrc. Please inspect your ~/.bashrc to clear any BCM-related content, if appropriate."
else
  echo "Writing commands to ~/.bashrc to support running BCM from the admin machine."
  echo $BCM_BASHRC_FLAG >> ~/.bashrc
  echo 'export BCM_LOCAL_GIT_REPO="'$BCM_LOCAL_GIT_REPO'"' >> ~/.bashrc
  echo 'alias bcm="source $BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh"' >> ~/.bashrc

  echo "    Run 'bcm' to load BCM environment variables FOR THE CURRENT LXD endpoint."
  echo "    Run 'lxc remote get-default' to determine your current LXD endpoint. Run 'lxc remote set-default <endpoint>' to change the LXD endpoint."
  echo ""

  # git commit
  bash -c "$BCM_LOCAL_GIT_REPO/resources/commit_bcm.sh"
fi

# next let's install the software.
bash -c "./install_software.sh"