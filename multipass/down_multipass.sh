#!/bin/bash

# source the parameters
source ~/.bcm/multipass.env.sh

# Stopping multipass vm $MULTIPASS_VM_NAME
if [[ $(multipass list | grep $MULTIPASS_VM_NAME) ]]; then
  echo "Stopping multipass vm $MULTIPASS_VM_NAME"
  sudo multipass stop $MULTIPASS_VM_NAME
  sudo multipass delete $MULTIPASS_VM_NAME
  sudo multipass purge
else
  echo "No $MULTIPASS_VM_NAME multipass exists to stop, delete, and purge."
fi

# Removing lxc remote vm
if [[ $(lxc remote get-default) = $MULTIPASS_VM_NAME ]]; then
    echo "Removing lxd remote $MULTIPASS_VM_NAME"
    lxc remote set-default local
    lxc remote remove $MULTIPASS_VM_NAME
else
    echo "No lxc remote called $MULTIPASS_VM_NAME to delete."
fi