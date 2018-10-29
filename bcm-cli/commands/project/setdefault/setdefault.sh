#!/bin/bash

set -eu 

#bcm="$BCM_LOCAL_GIT_REPO/bcm-cli/bcm.sh"
CURRENT_BCM_PROJECT=$($BCM_LOCAL_GIT_REPO/bcm-cli/bcm.sh project get-default)

if [[ $BCM_DEBUG = "true" ]]; then
    echo "CURRENT_BCM_PROJECT: $CURRENT_BCM_PROJECT"
    echo "BCM_NEW_PROJECT_NAME: $BCM_NEW_PROJECT_NAME"
fi

if $BCM_LOCAL_GIT_REPO/bcm-cli/bcm.sh project list | grep -q -x $BCM_NEW_PROJECT_NAME ; then
    echo "#!/bin/bash" > ~/.bcm/projects/bcm.client.sh
    echo "export BCM_PROJECT_NAME=$BCM_NEW_PROJECT_NAME" >> ~/.bcm/projects/bcm.client.sh
else
    echo "Project '$BCM_NEW_PROJECT_NAME' doesn't exist. You can create the project by running 'bcm project create $BCM_NEW_PROJECT_NAME'."
fi