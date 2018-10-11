#!/bin/bash

set -eu

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"


# quit if there are no multipass environment variables loaded.
if [[ -z $(env | grep "BCM_MULTIPASS_") ]]; then
  echo "MULTIPASS environment variables not set. Please source update and source ~/bcm/lxd_endpoints.sh"
  exit 1
fi

# Stopping multipass vm $MULTIPASS_VM_NAME
if [[ $(multipass list | grep "$BCM_MULTIPASS_VM_NAME") ]]; then
  if [[ $(multipass list | grep "$BCM_MULTIPASS_VM_NAME") != "No instances found." ]]; then
    echo "Stopping multipass vm $BCM_MULTIPASS_VM_NAME"
    sudo multipass stop $BCM_MULTIPASS_VM_NAME
    sudo multipass delete $BCM_MULTIPASS_VM_NAME
    sudo multipass purge
  else
    echo "No '$BCM_MULTIPASS_VM_NAME' multipass exists to stop, delete, and purge."
    exit 0
  fi
else
  echo "$BCM_MULTIPASS_VM_NAME doesn't exist."
fi

# Removing lxc remote vm
if [[ $(lxc remote get-default) = $BCM_MULTIPASS_VM_NAME ]]; then
    echo "Removing lxd remote $BCM_MULTIPASS_VM_NAME"
    lxc remote set-default local
    lxc remote remove $BCM_MULTIPASS_VM_NAME
else
    echo "No lxc remote called $BCM_MULTIPASS_VM_NAME to delete."
fi

if [[ -f ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env ]]; then
  rm ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
fi

if [[ -d ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME ]]; then
  rm -rf ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME
fi

cd ~/.bcm
git add *
git commit -am "Removed ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env and ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME"
cd -