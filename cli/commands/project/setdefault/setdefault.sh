#!/bin/bash

set -eu 

#bcm="bcm"
CURRENT_BCM_PROJECT=$(bcm project get-default)

if [[ $BCM_DEBUG = "true" ]]; then
    echo "CURRENT_BCM_PROJECT: $CURRENT_BCM_PROJECT"
    echo "BCM_NEW_PROJECT_NAME: $BCM_NEW_PROJECT_NAME"
fi

if bcm project list | grep -q -x $BCM_NEW_PROJECT_NAME ; then
    echo "#!/bin/bash" > ~/.bcm/projects/bcm.client.sh
    echo "export BCM_PROJECT_NAME=$BCM_NEW_PROJECT_NAME" >> ~/.bcm/projects/bcm.client.sh
else
    echo "Project '$BCM_NEW_PROJECT_NAME' doesn't exist. You can create the project by running 'bcm project create $BCM_NEW_PROJECT_NAME'."
fi