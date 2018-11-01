#!/bin/bash

set -eu


#let's update our ENV to include the appropriate information from the
#LXD cluster master. Grab the info then switch back to the new VM that we're creating.
NEW_VM_NAME=$BCM_CLUSTER_ENDPOINT_NAME
export CLUSTER_MASTER_ENV_DIR=$ENDPOINTS_DIR/$BCM_LXD_CLUSTER_MASTER
source $CLUSTER_MASTER_ENV_DIR/.env
export BCM_LXD_CLUSTER_MASTER_PASSWORD=$BCM_LXD_SECRET
export BCM_CLUSTER_ENDPOINT_NAME=$NEW_VM_NAME
NEW_VM_DIR=$ENDPOINTS_DIR/$BCM_CLUSTER_ENDPOINT_NAME
source $NEW_VM_DIR/.env

export BCM_LXD_CLUSTER_MASTER_IP=$(multipass list | grep "$BCM_LXD_CLUSTER_MASTER" | awk '{ print $3 }')

touch /tmp/bcm/cert.txt
echo "-----BEGIN CERTIFICATE-----" > /tmp/bcm/cert.txt
echo "" >> /tmp/bcm/cert.txt
grep -v '\-\-\-\-\-' $CLUSTER_MASTER_ENV_DIR/lxd/lxd.cert | sed ':a;N;$!ba;s/\n/\n\n/g' | sed 's/^/      /' >> /tmp/bcm/cert.txt
echo "" >> /tmp/bcm/cert.txt
echo "      -----END CERTIFICATE-----" >> /tmp/bcm/cert.txt
echo "" >> /tmp/bcm/cert.txt

export BCM_LXD_CLUSTER_CERTIFICATE=$(cat /tmp/bcm/cert.txt)
mkdir -p $NEW_VM_DIR/lxd
envsubst < ./lxd_preseed/lxd_member_preseed.yml > $NEW_VM_DIR/lxd/preseed.yml

# upload the lxd preseed file to the multipass vm.
multipass copy-files $NEW_VM_DIR/lxd/preseed.yml $BCM_CLUSTER_ENDPOINT_NAME:/home/multipass/preseed.yml

# now initialize the LXD daemon on the VM.
multipass exec $BCM_CLUSTER_ENDPOINT_NAME -- sh -c "cat /home/multipass/preseed.yml | sudo lxd init --preseed"

bash -c "$BCM_LOCAL_GIT_REPO/cli/commands/commit_bcm.sh 'Added files associated with provision_lxd_member.sh'"
