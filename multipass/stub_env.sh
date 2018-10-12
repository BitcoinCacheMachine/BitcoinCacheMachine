#!/bin/bash

  # create the file
  touch ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
  echo "#!/bin/bash" >> ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
  echo "" >> ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
  echo "export BCM_MULTIPASS_VM_NAME="'"'$BCM_MULTIPASS_VM_NAME'"' >> ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
  cat $BCM_LOCAL_GIT_REPO/resources/bcm/default_endpoints/multipass_defaults.env >> ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env
  
  # generate an LXD secret for the new VM lxd endpoint.
  BCM_LXD_SECRET=$(apg -n 1 -m 30 -M CN)
  echo "export BCM_LXD_SECRET="'"'$BCM_LXD_SECRET'"' >> ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env

  echo "~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env has been created."
  echo "Continue by sourcing the variables by running:  source ~/.bcm/endpoints/$BCM_MULTIPASS_VM_NAME.env"