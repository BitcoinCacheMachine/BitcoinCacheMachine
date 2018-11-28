#!/bin/bash

# quit if error
set -Eeuo pipefail

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# let's create a client certificate for the instance and store it in /etc/docker/certs.d/$INSTANCE_NAME/
# https://docs.docker.com/engine/security/certificates/#understanding-the-configuration
BCM_BCMNETINST_RSYNC_BUILDER_NAME="bcm-rsync-builder"
bash -c "$BCM_LXD_OPS/generate_and_sign_client_certificate.sh $BCM_BCMNETINST_RSYNC_BUILDER_NAME rsyncd $BCM_BCMNETINST_RSYNC_BUILDER_NAME"

# let's get a fresh LXC host that's configured to push/pull to gateway registreis
bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/bcmnet/create_instance_from_snapshot.sh $BCM_BCMNETINST_RSYNC_BUILDER_NAME rsyncd $BCM_BCMNETINST_RSYNC_BUILDER_NAME"

#for debugging in curl
lxc exec $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME -- apt-get install strace -y

lxc exec $BCM_BCMNETINST_RSYNC_BUILDER_NAME -- mkdir -p /apps/rsyncd

lxc file push ./image/Dockerfile bcm-rsync-builder/apps/rsyncd/Dockerfile
lxc file push ./image/entrypoint.sh $BCM_BCMNETINST_RSYNC_BUILDER_NAME/apps/rsyncd/entrypoint.sh

# build the rsync image. We don't need to put it in a private registry I don't think.
lxc exec $BCM_BCMNETINST_RSYNC_BUILDER_NAME -- docker build -t bcm-rsync:latest /apps/rsyncd
lxc exec $BCM_BCMNETINST_RSYNC_BUILDER_NAME -- docker push bcm-rsync:latest

# lxc delete --force $BCM_BCMNETINST_RSYNC_BUILDER_NAME
# lxc storage delete $BCM_BCMNETINST_RSYNC_BUILDER_NAME-dockervol





# let's get a fresh LXC host that's configured to push/pull to gateway registreis
#bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/bcmnet/delete_instance.sh bcm-rsync-builder"




# if [[ ! -f $BCM_RUNTIME_DIR/endpoints/"$(lxc remote get-default)"/.ssh/cachestack-rsync-key.pub ]]; then
#     echo "Generating SSH keys for rsync authentication. Storing at $BCM_RUNTIME_DIR/endpoints/"$(lxc remote get-default)"/.ssh/cachestack-rsync-key.pub"
#     mkdir -p $BCM_RUNTIME_DIR/endpoints/"$(lxc remote get-default)"/.ssh
#     ssh-keygen -t rsa -b 2048 -f $BCM_RUNTIME_DIR/endpoints/"$(lxc remote get-default)"/.ssh/cachestack-rsync-key
# fi

# echo "Deploying rsyncd to 'cachestack'."
# lxc exec cachestack -- mkdir -p /apps/rsyncd
# lxc exec cachestack -- mkdir -p /apps/rsyncd/.ssh
# lxc file push $BCM_RUNTIME_DIR/endpoints/"$(lxc remote get-default)"/.ssh/cachestack-rsync-key.pub cachestack/apps/rsyncd/authorized_keys
# lxc file push ./rsyncd.conf cachestack/apps/rsyncd/rsyncd.conf
# lxc file push ./rsyncd.yml cachestack/apps/rsyncd/rsyncd.yml
# lxc exec cachestack -- env BCS_INSTALL_RSYNCD_BUILD_IMAGE=$BCS_INSTALL_RSYNCD_BUILD_IMAGE docker stack deploy -c /apps/rsyncd/rsyncd.yml rsyncd

# wait-for-it -t 0 cachestack.lxd:2222

# if [[ $BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED = "true" ]]; then
#     lxc exec cachestack -- mkdir -p cachestack/apps/bitcoind/data

#     # if the directory exists, then we're good to go.
#     if [ -d "$BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR" ]; then
    
#         # TODO ugprade basic authentication to SSH keys
#         echo "$BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR on $HOSTNAME will be pushed to cachestack rsyncd."
#         SSH_KEY_PATH="$BCM_RUNTIME_DIR/endpoints/lexx/.ssh/cachestack-rsync-key"

#         rsync -av -e "ssh -i $SSH_KEY_PATH -p 2222 -l rsync -o StrictHostKeyChecking=no" $BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR/ cachestack.lxd:bitcoind_testnet_data
#     fi
# fi
