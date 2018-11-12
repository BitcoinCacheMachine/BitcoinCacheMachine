#!/usr/bin/env bash

# This script iniitalizes the management computer that is executing 
# BCM-related LXD and multipass scripts against (local) or remote LXD
# endpoints.

set -e
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

# let's make sure the local git client is using TOR for git push/pull operations for the BCM github URL only.
BCM_GITHUB_URL="https://github.com/BitcoinCacheMachine/BitcoinCacheMachine"
BCM_LOCAL_REPO_HTTP_PROXY="socks5://localhost:9050"
if [[ $(git config --get --global http.$BCM_GITHUB_URL.proxy) != $BCM_LOCAL_REPO_HTTP_PROXY ]]; then
  echo "Setting git client to use local TOR proxy for URL '$BCM_GITHUB_URL'"
  git config --global "http.$BCM_GITHUB_URL.proxy" $BCM_LOCAL_REPO_HTTP_PROXY
fi

# get the current directory where this script is so we can reference it later
echo "Setting BCM_LOCAL_GIT_REPO_DIR environment variable in current shell to '$(pwd)'"
export BCM_LOCAL_GIT_REPO_DIR=$(pwd)
export BCM_RUNTIME_DIR="$HOME/.bcm"

BCM_BASHRC_START_FLAG='###START_BCM###'
BCM_BASHRC_END_FLAG='###END_BCM###'
if grep -Fxq "$BCM_BASHRC_START_FLAG" $HOME/.profile
then
  # code if found
  echo "BCM flag discovered in $HOME/.profile. Please inspect your $HOME/.profile to clear any BCM-related content, if appropriate."
else
  echo "Writing commands to $HOME/.profile to support running BCM from the admin machine."
  echo "$BCM_BASHRC_START_FLAG" >> $HOME/.profile
  echo "export BCM_LOCAL_GIT_REPO_DIR=$BCM_LOCAL_GIT_REPO_DIR" >> $HOME/.profile
  echo "export PATH="'$PATH:'""'$BCM_LOCAL_GIT_REPO_DIR/cli'"" >> $HOME/.profile
  echo "export BCM_RUNTIME_DIR=$BCM_RUNTIME_DIR" >> $HOME/.profile
  echo "$BCM_BASHRC_END_FLAG" >> $HOME/.profile
fi

echo "Done setting up your machine to use the Bitcoin Cache Machine CLI. Please open a new terminal session to refresh your envronment, then typ 'bcm' to continue."
export PATH=$PATH/$BCM_LOCAL_GIT_REPO_DIR






# # certificates - we store root certificates here
# if [ ! -d $BCM_RUNTIME_DIR/certs ]; then
#   echo "Creating BCM certs directory at $BCM_RUNTIME_DIR/certs"
#   mkdir -p $BCM_RUNTIME_DIR/certs

#   # TODO we will change the self-signed root certificate to use Trezor 
#   # generate the private key for the root certificate
#   # Docs: this is essentially the root-of-trust for your software-defined datacenter.
#   # I'll eventually source this key on a bitcoin hardware device using usb-based docker image.
#   openssl genrsa -out $BCM_RUNTIME_DIR/certs/rootca.key 4096

#   # We wil self-sign this certificate
#   # this is what we will install on all BCM LXC hosts as the root certificate to trust; any cert signed by rootca.key will be trusted
#   # and will be used as trust/authentication boundary, i.e., one self-signed Root CA per BIP32 path.
#   openssl req -x509 -subj "/C=US/ST=BCM/L=INTERNET/O=BCM/CN=BCM ROOT CA" -new -nodes -key $BCM_RUNTIME_DIR/certs/rootca.key -sha256 -days 365 -out $BCM_RUNTIME_DIR/certs/rootca.cert
#   echo "BCM certs directory exists at $BCM_RUNTIME_DIR/certs"
# fi