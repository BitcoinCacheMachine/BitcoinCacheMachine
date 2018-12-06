#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"
echo "git entrypoint.sh"

BCM_CLI_VERB=$2
BCM_HELP_FLAG=0
BCM_GIT_REPO_DIR=
BCM_CERT_DIR=
BCM_GIT_COMMIT_MESSAGE=
BCM_GIT_CLIENT_USERNAME=
BCM_GPG_SIGNING_KEY_ID=

for i in "$@"; do
	case $i in
	--cert-dir=*)
		BCM_CERT_DIR="${i#*=}"
		shift # past argument=value
		;;
	--git-repo-dir=*)
		BCM_GIT_REPO_DIR="${i#*=}"
		shift # past argument=value
		;;
	--git-commit-message=*)
		BCM_GIT_COMMIT_MESSAGE="${i#*=}"
		shift # past argument=value
		;;
	--git-username=*)
		BCM_GIT_CLIENT_USERNAME="${i#*=}"
		shift # past argument=value
		;;
	--email-address=*)
		BCM_EMAIL_ADDRESS="${i#*=}"
		shift # past argument=value
		;;
	--gpg-signing-key-id=*)
		BCM_GPG_SIGNING_KEY_ID="${i#*=}"
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

if [[ ! -d $BCM_CERT_DIR ]]; then
	echo "BCM_CERT_DIR '$BCM_CERT_DIR' doesn't exist."
	exit
fi
export BCM_CERT_DIR=$BCM_CERT_DIR

if [[ ! -d $BCM_GIT_REPO_DIR ]]; then
	echo "BCM_GIT_REPO_DIR '$BCM_GIT_REPO_DIR' doesn't exist."
	exit
fi
export BCM_GIT_REPO_DIR=$BCM_GIT_REPO_DIR

if [[ -z $BCM_GIT_CLIENT_USERNAME ]]; then
	echo "Required parameter BCM_GIT_CLIENT_USERNAME not specified. The git repo config user.name will be used."
else
	export BCM_GIT_CLIENT_USERNAME=$BCM_GIT_CLIENT_USERNAME
fi

if [[ -z $BCM_GIT_COMMIT_MESSAGE ]]; then
	echo "Required parameter BCM_GIT_COMMIT_MESSAGE not specified."
	exit
fi
export BCM_GIT_COMMIT_MESSAGE=$BCM_GIT_COMMIT_MESSAGE

if [[ -z $BCM_EMAIL_ADDRESS ]]; then
	echo "Required parameter BCM_EMAIL_ADDRESS not specified."
	exit
fi
export BCM_EMAIL_ADDRESS=$BCM_EMAIL_ADDRESS

if [[ -z $BCM_GPG_SIGNING_KEY_ID ]]; then
	echo "Required parameter BCM_GPG_SIGNING_KEY_ID not specified."
	exit
fi
export BCM_GPG_SIGNING_KEY_ID=$BCM_GPG_SIGNING_KEY_ID

# now call the appropritae script.
if [[ $BCM_CLI_VERB == "commit" ]]; then
	# if BCM_PROJECT_DIR is empty, we'll check to see if someone over-rode
	# the trezor directory. If so, we'll send that in instead.
	if [[ $BCM_HELP_FLAG == 1 ]]; then
		cat ./commands/git/commit/help.txt
		exit
	fi

	bash -c "$BCM_GIT_DIR/controller/build.sh"
	if docker image list | grep -q "bcm-gpgagent:latest"; then
		docker build -t bcm-gpgagent:latest .
	else
		# make sure the container is up-to-date, but don't display
		docker build -t bcm-gpgagent:latest . >>/dev/null
	fi

	if [[ $BCM_DEBUG == 1 ]]; then
		echo "BCM_CERT_DIR: $BCM_CERT_DIR"
		echo "BCM_GIT_COMMIT_MESSAGE: $BCM_GIT_COMMIT_MESSAGE"
		echo "BCM_GIT_REPO_DIR: $BCM_GIT_REPO_DIR"
		echo "BCM_GIT_CLIENT_USERNAME: $BCM_GIT_CLIENT_USERNAME"
		echo "BCM_EMAIL_ADDRESS: $BCM_EMAIL_ADDRESS"
		echo "BCM_GPG_SIGNING_KEY_ID: $BCM_GPG_SIGNING_KEY_ID"
	fi

	if ! docker ps | grep -q "gitter"; then
		# shellcheck disable=SC1090
		source "$BCM_GIT_DIR/controller/export_usb_path.sh"
		docker run -d --name gitter \
			-v $BCM_CERT_DIR:/root/.gnupg \
			-v $BCM_GIT_REPO_DIR:/gitrepo \
			--device="$BCM_TREZOR_USB_PATH" \
			-e BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME" \
			-e BCM_EMAIL_ADDRESS="$BCM_EMAIL_ADDRESS" \
			-e BCM_GIT_COMMIT_MESSAGE="$BCM_GIT_COMMIT_MESSAGE" \
			-e BCM_GPG_SIGNING_KEY_ID="$BCM_GPG_SIGNING_KEY_ID" \
			bcm-gpgagent:latest

		sleep 2
	fi

	if docker ps | grep -q "gitter"; then
		docker exec -it gitter /bcm/commit_sign_git_repo.sh
		docker kill gitter >/dev/null
		docker system prune -f >/dev/null
	else
		echo "Error. Docker container 'gitter' was not running."
	fi

elif [[ $BCM_CLI_VERB == "push" ]]; then
	echo "git push TODO"
else
	cat ./git/help.txt
fi
