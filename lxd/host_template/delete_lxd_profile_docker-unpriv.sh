#/bin/bash

# delete lxd profile docker_unpriv
if [[ $(lxc profile list | grep "docker_unpriv") ]] ; then
  # make sure it doesn't have anything attached to it.
  if [[ ! -z $(lxc profile list | grep docker_unpriv | grep "| 0") ]]; then
    echo "Deleting lxc profile docker_unpriv to default settings."
    lxc profile delete docker_unpriv
  else
    echo "Could not delete lxc profile 'docker_unpriv' due to attached resources. Check your BCM environment variables."
  fi
fi
