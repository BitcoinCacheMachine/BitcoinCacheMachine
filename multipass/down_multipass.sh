#!/bin/bash

set -eu

# quit if there are no multipass environment variables loaded.
if [[ -z $(env | grep "MULTIPASS_") ]]; then
  echo "MULTIPASS environment variables not set. Please source update and source ~/bcm/lxd_endpoints.sh"
  quit
fi

# Stopping multipass vm $MULTIPASS_VM_NAME
if [[ $(multipass list | grep "$MULTIPASS_VM_NAME") ]]; then
  if [[ $(multipass list | grep "$MULTIPASS_VM_NAME") != "No instances found." ]]; then
    echo "Stopping multipass vm $MULTIPASS_VM_NAME"
    sudo multipass stop $MULTIPASS_VM_NAME
    sudo multipass delete $MULTIPASS_VM_NAME
    sudo multipass purge
  else
    echo "No '$MULTIPASS_VM_NAME' multipass exists to stop, delete, and purge."
    exit 0
  fi
else
  echo "$MULTIPASS_VM_NAME doesn't exist."
fi

# Removing lxc remote vm
if [[ $(lxc remote get-default) = $MULTIPASS_VM_NAME ]]; then
    echo "Removing lxd remote $MULTIPASS_VM_NAME"
    lxc remote set-default local
    lxc remote remove $MULTIPASS_VM_NAME
else
    echo "No lxc remote called $MULTIPASS_VM_NAME to delete."
fi

echo "Note! You MUST DELETE ~/.bcm/runtime/$MULTIPASS_VM_NAME/cloud-init.yml MANUALLY!!!"