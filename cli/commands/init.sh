#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC2153
BCM_CERT_DIR="$BCM_CERTS_DIR"
BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_FQDN=

for i in "$@"; do
	case $i in
	--cert-dir=*)
		BCM_CERT_DIR="${i#*=}"
		shift # past argument=value
		;;
	--cert-name=*)
		BCM_CERT_NAME="${i#*=}"
		shift # past argument=value
		;;
	--cert-username=*)
		BCM_CERT_USERNAME="${i#*=}"
		shift # past argument=value
		;;
	--cert-fqdn=*)
		BCM_CERT_FQDN="${i#*=}"
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

if [[ $BCM_HELP_FLAG == 1 ]]; then
	cat ./init-help.txt
	exit
fi

if [[ -z $BCM_CERT_NAME ]]; then
	echo "BCM_CERT_NAME not set."
	exit
fi

if [[ -z $BCM_CERT_USERNAME ]]; then
	echo "BCM_CERT_USERNAME not set."
	exit
fi

if [[ -z $BCM_CERT_FQDN ]]; then
	echo "BCM_CERT_FQDN not set."
	exit
fi

# shellcheck disable=SC2153
bash -c "$BCM_GIT_DIR/cli/commands/git_init_dir.sh $BCM_CERT_DIR"

bash -c "$BCM_GIT_DIR/controller/gpg-init.sh \
    --cert-dir='$BCM_CERT_DIR' \
    --cert-name='$BCM_CERT_NAME' \
    --cert-username='$BCM_CERT_USERNAME' \
--cert-hostname='$BCM_CERT_FQDN'"

# now let's initialize the password repository with the GPG key
bash -c "$BCM_GIT_DIR/controller/gpg_pass_init.sh"

# ok great, now we have it initialized. Let's create a new GPG-encrypted password
# file for the encfs mount on our controller machine. This allows us to encrypt the
# BCM files on disk using a password backed by the trezor.
BCM_PASS_ENCFS_PATH="bcm/controller/encfs"

bcm pass new --name="$BCM_PASS_ENCFS_PATH"

mkdir -p "$BCM_ENCRYPTED_DIR"
mkdir -p "$BCM_UNENCRYPTED_VIEW_DIR"

# 60 minute idle timeout in which case the encrypted mount will be unmounted
encfs -o allow_root "$BCM_ENCRYPTED_DIR" "$BCM_UNENCRYPTED_VIEW_DIR" -i=60 --paranoia --extpass="bcm pass get --name=$BCM_PASS_ENCFS_PATH" >>/dev/null
echo "Created $BCM_RUNTIME_DIR/ on $(date -u "+%Y-%m-%dT%H:%M:%S %Z")." >"$BCM_RUNTIME_DIR/debug.log"

# shellcheck disable=SC2153
bash -c "$BCM_GIT_DIR/cli/commands/git_init_dir.sh $BCM_PROJECTS_DIR"
bash -c "$BCM_GIT_DIR/cli/commands/git_init_dir.sh $BCM_CLUSTERS_DIR"
bash -c "$BCM_GIT_DIR/cli/commands/git_init_dir.sh $BCM_DEPLOYMENTS_DIR"
bash -c "$BCM_GIT_DIR/cli/commands/git_init_dir.sh $BCM_SSH_DIR"
