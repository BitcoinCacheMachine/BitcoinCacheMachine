#/bin/bash

# delete lxd profile docker_priv
if [[ $(lxc profile list | grep "docker_priv") ]] ; then
  # make sure it doesn't have anything attached to it.
  if [[ ! -z $(lxc profile list | grep docker_priv | grep "| 0") ]]; then
    echo "Deleting lxc profile docker_priv to default settings."
    lxc profile delete docker_priv
  else
    echo "Could not delete lxc profile 'docker_priv' due to attached resources. Check your BCM environment variables."
  fi
fi
