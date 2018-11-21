#!/usr/bin/env bash

set -Eeuo pipefail
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
if [[ $(git config --get --global http.$BCM_GITHUB_URL.proxy) != "$BCM_LOCAL_REPO_HTTP_PROXY" ]]; then
  echo "Setting git client to use local TOR proxy for URL '$BCM_GITHUB_URL'"
  git config --global "http.$BCM_GITHUB_URL.proxy" $BCM_LOCAL_REPO_HTTP_PROXY
fi

# get the current directory where this script is so we can reference it later
echo "Setting BCM_LOCAL_GIT_REPO_DIR environment variable in current shell to '$(pwd)'"
BCM_LOCAL_GIT_REPO_DIR=$(pwd)
export BCM_LOCAL_GIT_REPO_DIR

export BCM_RUNTIME_DIR="$HOME/.bcm"

BCM_BASHRC_START_FLAG='###START_BCM###'
BCM_BASHRC_END_FLAG='###END_BCM###'
PROFILE_FILE="$HOME/.profile"
if grep -Fxq "$BCM_BASHRC_START_FLAG" "$PROFILE_FILE"
then
  # code if found
  echo "BCM flag discovered in $HOME/.profile. Please inspect your $HOME/.profile to clear any BCM-related content, if appropriate."
else
  echo "Writing commands to $HOME/.profile to support running BCM from the admin machine."

  {
    echo "$BCM_BASHRC_START_FLAG"
    echo "export BCM_LOCAL_GIT_REPO_DIR=$BCM_LOCAL_GIT_REPO_DIR"
    echo "export PATH="'$PATH:'""'$BCM_LOCAL_GIT_REPO_DIR/cli'""
    echo "export BCM_RUNTIME_DIR=$BCM_RUNTIME_DIR"
    echo "$BCM_BASHRC_END_FLAG"
  } >> "$PROFILE_FILE"
fi

echo "Done setting up your machine to use the Bitcoin Cache Machine CLI. Type 'bcm' to continue."
export PATH=$PATH/$BCM_LOCAL_GIT_REPO_DIR