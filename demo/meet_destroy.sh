#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/.env"
source ./meetup.env

bcm project undeploy --project-name="$BCM_PROJECT_NAME" --cluster-name="$BCM_CLUSTER_NAME" --force || true

bcm cluster destroy --cluster-name="$BCM_CLUSTER_NAME"

if [[ -d "$BCM_UNENCRYPTED_VIEW_DIR" ]]; then
	fusermount -u -q "$BCM_UNENCRYPTED_VIEW_DIR" || true
	sleep 2
	sudo rm -Rf "$BCM_UNENCRYPTED_VIEW_DIR"
	sudo rm -Rf "$BCM_ENCRYPTED_DIR"
fi

if [[ -d $GNUPGHOME ]]; then
	if [[ $GNUPGHOME != "$HOME/.password_store" ]]; then
		echo "Deleting $GNUPGHOME."
		sudo rm -Rf "$GNUPGHOME"
	fi
fi

if [[ -d $PASSWORD_STORE_DIR ]]; then
	if [ "$PASSWORD_STORE_DIR" != "$HOME/.password_store" ]; then
		echo "Deleting $PASSWORD_STORE_DIR."
		sudo rm -Rf "$PASSWORD_STORE_DIR"
	fi
fi

if [[ -d $SSH_DIR ]]; then
	if [ "$SSH_DIR" != "$HOME/.ssh" ]; then
		echo "Deleting $SSH_DIR."
		sudo rm -Rf "SSH_DIR"
	fi
fi

if [[ -f "$BCM_RUNTIME_DIR/.env" ]]; then
	rm "$BCM_RUNTIME_DIR/.env"
fi
