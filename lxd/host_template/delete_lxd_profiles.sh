#!/bin/bash


# delete lxd profile docker
if [[ $(lxc profile list | grep "default") ]] ; then
  # make sure it doesn't have anything attached to it.
  if [[ ! -z $(lxc profile list | grep default | grep "| 0") ]]; then
    echo "Restoring lxc profile default to default settings."
    cat ./lxd_profiles/default.yml | lxc profile edit default
  else
    echo "Could not delete lxd profile 'default' due to attached resources. Check your BCM environment variables."
  fi
fi


# delete lxd profile docker_priv
if [[ $(lxc profile list | grep "docker_priv") ]] ; then
  # make sure it doesn't have anything attached to it.
  if [[ ! -z $(lxc profile list | grep docker | grep "| 0") ]]; then
    echo "Deleting docker_priv lxd profile."
    lxc profile delete docker_priv
  else
    echo "Could not delete lxd profile 'docker_priv' due to attached resources. Check your BCM environment variables."
  fi
fi

# delete lxd profile docker_unpriv
if [[ $(lxc profile list | grep "docker_unpriv") ]] ; then
  # make sure it doesn't have anything attached to it.
  if [[ ! -z $(lxc profile list | grep "docker_unpriv" | grep "| 0") ]]; then
    echo "Deleting docker_unpriv lxd profile."
    lxc profile delete docker_unpriv
  else
    echo "Could not delete lxd profile 'docker_unpriv' due to attached resources. Check your BCM environment variables."
  fi
fi

