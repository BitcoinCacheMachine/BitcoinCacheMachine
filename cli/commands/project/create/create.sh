#!/bin/bash

set -eu
cd "$(dirname "$0")"

BCM_PROJECT_NAME=$BCM_PROJECT_NAME
BCM_PROJECT_DIR=$BCM_PROJECTS_DIR/$BCM_PROJECT_NAME

# if $BCM_PROJECTS_DIR doesn't exist, create it.
if [ ! -d $BCM_PROJECTS_DIR ]; then
    echo "Creating lxd_projects directory at $BCM_PROJECTS_DIR"
    mkdir -p $BCM_PROJECTS_DIR
fi

# if the directory already exists we're going to quit
if [[ -d $BCM_PROJECT_DIR ]]; then
    echo "BCM project definition already exists. If you want to remove it, run 'bcm project destroy $BCM_PROJECT_NAME'"
    cat ./help.txt
    exit
else
    echo "Creating bcm project directory at $BCM_PROJECT_DIR"
    mkdir -p $BCM_PROJECT_DIR
    touch $BCM_PROJECT_DIR/.env
    echo "#!/bin/bash" >> $BCM_PROJECT_DIR/.env
fi