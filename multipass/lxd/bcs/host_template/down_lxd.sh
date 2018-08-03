#!/bin/bash

set -e

# delete dockertemplate
if [[ $(lxc list | grep dockertemplate) ]]; then
    echo "Deleting dockertemplate lxd host."
    lxc delete --force dockertemplate
fi


# delete lxd network lxdbr0
if [[ $(lxc network list | grep lxdbr0) ]]; then
    echo "Deleting network lxdbr0."
    lxc network delete lxdbr0
fi



# if specified, delete the template and lxd base image
if [[ $BC_HOST_TEMPLATE_DELETE = "true" ]]; then\
    if [[ $(lxc image list | grep 38219778c2cf) ]]; then
        echo "Destrying lxd image '38219778c2cf'."
        lxc image delete 38219778c2cf
    fi
fi



# delete lxd profile dockertemplate_profile
if [[ $(lxc profile list | grep docker) ]] ; then
  # make sure it doesn't have anything attached to it.
  if [[ ! -z $(lxc profile list | grep docker | grep "| 0") ]]; then
    echo "Deleting docker lxd profile."
    lxc profile delete docker
  else
    echo "Could not delete lxd profile 'docker' due to attached resources. Check your BCM environment variables."
  fi
fi
