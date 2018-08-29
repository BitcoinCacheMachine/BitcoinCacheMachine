#/bin/bash

# delete lxd profile docker_privileged
if [[ $(lxc profile list | grep "docker_privileged") ]] ; then
  # make sure it doesn't have anything attached to it.
  if [[ ! -z $(lxc profile list | grep docker_privileged | grep "| 0") ]]; then
    echo "Deleting lxc profile docker_privileged to default settings."
    lxc profile delete docker_privileged
  else
    echo "Could not delete lxc profile 'docker_privileged' due to attached resources. Check your BCM environment variables."
  fi
fi
