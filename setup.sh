#!/bin/bash

# This script iniitalizes the management computer that is executing 
# BCM-related LXD and multipass scripts against (local) or remote LXD
# endpoints.

# quit if there's an error
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# get the current directory where this script is so we can reference it later, namely in .bashrc
# file on the admin machine.
SCRIPT_DIR=$(pwd)

# install LXD on the admin machine.
sudo apt-get update && sudo apt install -y zfsutils-linux wait-for-it lxd rsync apg encfs

# if ~/.bcm doesn't exist, create it
if [ ! -d ~/.bcm ]; then
  echo "Creating Bitcoin Cache Machine config directory at ~/.bcm"
  mkdir -p ~/.bcm
fi

# if ~/.bcm/endpoints doesn't exist, create it.
if [ ! -d ~/.bcm/endpoints ]; then
  echo "Creating BCM endpoints directory at ~/.bcm/endpoints"
  mkdir -p ~/.bcm/endpoints
fi


# if ~/.bcm/endpoints doesn't exist, create it.
if [ ! -f ~/.bcm/endpoints/local.env ]; then
  echo "Creating ~/.bcm/endpoints/local.env"
  touch ~/.bcm/endpoints/local.env

  echo "#!/bin/bash" >> ~/.bcm/endpoints/local.env
else
  echo "BCM endpoints config directory exists at ~/.bcm/endpoints"
fi

# if ~/.bcm/runtime doesn't exist create it
if [ ! -d ~/.bcm/runtime ]; then
  echo "Creating BCM runtime directory at ~/.bcm/runtime"
  mkdir -p ~/.bcm/runtime
else
  echo "BCM runtime directory exists at ~/.bcm/runtime"
fi


echo "Writing commands to ~/.bashrc to support running BCM from the admin machine."

BCM_BASHRC_FLAG='### Start BCM'

if grep -Fxq "$BCM_BASHRC_FLAG" ~/.bashrc
then
  # code if found
  echo "BCM flag discovered in ~/.bashrc. Please inspect your ~/.bashrc to clear any BCM-related content, if appropriate."
else
  echo $BCM_BASHRC_FLAG >> ~/.bashrc
  echo 'export BCM_LOCAL_GIT_REPO="'$SCRIPT_DIR'"' >> ~/.bashrc
  echo 'alias bcm="source $BCM_LOCAL_GIT_REPO/resources/bcm/admin_load_bcm_env.sh"' >> ~/.bashrc
  echo 'lxc remote set-default local' >> ~/.bashrc
  echo '### END BCM' >> ~/.bashrc

  echo "Done. Execute 'bcm' to load BCM environment variables FOR THE CURRENT LXD endpoint."
  echo "Run 'lxc remote get-default' to determine your current LXD endpoint. Run 'lxc remote set-default ENDPOINT' to change the LXD endpoint."

  echo "Setting BCM_LOCAL_GIT_REPO ENV VAR in current shell to '$SCRIPT_DIR'"
  source env BCM_LOCAL_GIT_REPO=$SCRIPT_DIR
fi
