#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_RUNTIME_DIR=

for i in "$@"; do
	case $i in
	--runtime-dir=*)
		BCM_RUNTIME_DIR="${i#*=}"
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

if [[ -z $BCM_RUNTIME_DIR ]]; then
	BCM_RUNTIME_DIR="$HOME/.bcm"
fi

# let's set the local git client user and email settings to prevent error messages.
if [[ -z $(git config --get --local user.name) ]]; then
	git config --local user.name "bcm"
fi

if [[ -z $(git config --get --local user.email) ]]; then
	git config --local user.email "bcm@$(hostname)"
fi

# let's make sure the local git client is using TOR for git pull operations.
# this should have been configured on a global level already, but we'll set the local
# settings as well.
BCM_TOR_PROXY="socks5://localhost:9050"
if [[ $(git config --get --local http.proxy) != "$BCM_TOR_PROXY" ]]; then
	echo "Setting git client to use local SOCKS5 TOR proxy for push/pull operations."
	git config --local http.proxy "$BCM_TOR_PROXY"
fi

# get the current directory where this script is so we can set ENVs
echo "Setting BCM_GIT_DIR environment variable in current shell to '$(pwd)'"
BCM_GIT_DIR=$(pwd)
export BCM_GIT_DIR="$BCM_GIT_DIR"
export BCM_RUNTIME_DIR="$BCM_RUNTIME_DIR"

# commands in ~/.bashrc are delimited by these literals.
BCM_BASHRC_START_FLAG='###START_BCM###'
BCM_BASHRC_END_FLAG='###END_BCM###'
BASHRC_FILE="$HOME/.bashrc"

if grep -Fxq "$BCM_BASHRC_START_FLAG" "$BASHRC_FILE"; then
	# code if found
	echo "BCM flag discovered in '$BASHRC_FILE'. Please inspect your '$BASHRC_FILE' to clear any BCM-related content, if appropriate."
	exit
else
	echo "Writing commands to '$BASHRC_FILE' to enable the BCM CLI."
	{
		echo "$BCM_BASHRC_START_FLAG"
		echo "export BCM_GIT_DIR=$BCM_GIT_DIR"
		echo "export BCM_RUNTIME_DIR=$BCM_RUNTIME_DIR"

		# shellcheck disable=SC2016
		echo "export PATH="'$PATH:'""'$BCM_GIT_DIR/cli'""
		echo "$BCM_BASHRC_END_FLAG"
	} >>"$BASHRC_FILE"
fi

echo "Done setting up your machine to use the Bitcoin Cache Machine CLI. Open a new terminal then type 'bcm --help'."
