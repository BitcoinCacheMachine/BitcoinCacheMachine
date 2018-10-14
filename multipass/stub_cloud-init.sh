#!/bin/bash

# type can be "master" or "member"
TYPE=$1

if [ $TYPE != "master" ] && [ $TYPE != "member" ]; then
    echo "Incorrect usage. Arguments are 'master' and 'member'."    
    exit
fi

mkdir -p ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME
touch ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml

if [ $TYPE = "master" ]; then
    # generate an LXD secret for the new VM lxd endpoint.
    envsubst < ./cloud_init/lxd_master_preseed.yml > ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml
fi

if [ $TYPE = "member" ]; then
    export BCM_LXD_CLUSTER_MASTER=$2
    export BCM_LXD_CLUSTER_MASTER_IP=$(multipass list | grep "$BCM_LXD_CLUSTER_MASTER" | awk '{ print $3 }')
    export BCM_LXD_CLUSTER_CERTIFICATE=$(sed ':a;N;$!ba;s/\n/\n\n/g' ~/.bcm/certs/$BCM_LXD_CLUSTER_MASTER/lxd.cert | sed 's/^/    /')
    envsubst < ./cloud_init/lxd_member_preseed.yml > ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml
fi



cd ~/.bcm
git add *
git commit -am "Added ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml"
cd -







#sed 's/CHANGEME/'$BCM_LXD_SECRET'/g' './cloud_init_files/lxd_cluster_'$TYPE'_preseed_template.yml'  > /tmp/bcm/$BCM_MULTIPASS_VM_NAME-lxd_preseed.yml

# Now update the VMName in the preseed file.
#sed 's/VMNAME/'$BCM_MULTIPASS_VM_NAME'/g' /tmp/bcm/$BCM_MULTIPASS_VM_NAME-lxd_preseed.yml  > /tmp/bcm/$BCM_MULTIPASS_VM_NAME-lxd_preseed_complete.yml





# if [ $TYPE = "member" ]; then
#   mkdir -p ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME
#   envsubst < ./cloud_init_files/lxd_master_preseed.yml > ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/lxd_preseed.yml
# fi





# if [ $TYPE = "member" ]; then
#     # Let's update member-specific cloud-init file.
#     MASTER_IP_ADDRESS=$(multipass list | grep "$BCM_MULTIPASS_VM_NAME" | awk '{ print $3 }')
#     sed 's/CLUSTERADDRESS/'$MASTER_IP_ADDRESS'/g' /tmp/bcm/$BCM_MULTIPASS_VM_NAME-lxd_preseed_complete.yml  > /tmp/bcm/$BCM_MULTIPASS_VM_NAME-lxd_preseed_complete.yml
#     CLUSTER_CERTIFICATE="test"
#     CLUSTER_PASSWORD="test1"
#     #sed 's/CLUSTER_CERTIFICATE/'$MASTER_IP_ADDRESS'/g' /tmp/bcm/$BCM_MULTIPASS_VM_NAME-lxd_preseed.yml  > /tmp/bcm/$BCM_MULTIPASS_VM_NAME-lxd_preseed_complete.yml
# fi



