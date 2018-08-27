#/bin/bash

# delete lxd profile bcm_disk
if [[ $(lxc profile list | grep "bcm_disk") ]] ; then
  # make sure it doesn't have anything attached to it.
  if [[ ! -z $(lxc profile list | grep bcm_disk | grep "| 0") ]]; then
    echo "Deleting lxc profile bcm_disk to default settings."
    lxc profile delete bcm_disk
  else
    echo "Could not delete lxc profile 'bcm_disk' due to attached resources. Check your BCM environment variables."
  fi
fi
