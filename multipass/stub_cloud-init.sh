#!/bin/bash

# type can be "master" or "member"
TYPE=$1

if [ $TYPE != "master" ] && [ $TYPE != "member" ]; then
    echo "Incorrect usage. Arguments are 'master' and 'member'."    
    exit
fi

sed 's/CHANGEME/'$BCM_LXD_SECRET'/g' './cloud_init_files/lxd_cluster_'$TYPE'_preseed_template.yml'  > /tmp/bcm/$BCM_MULTIPASS_VM_NAME-lxd_preseed.yml

# Now update the VMName in the preseed file.
sed 's/VMNAME/'$BCM_MULTIPASS_VM_NAME'/g' /tmp/bcm/$BCM_MULTIPASS_VM_NAME-lxd_preseed.yml  > /tmp/bcm/$BCM_MULTIPASS_VM_NAME-lxd_preseed_complete.yml


cat ./cloud_init_files/multipass_cloud-init_1.yml > ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml
cat /tmp/bcm/$BCM_MULTIPASS_VM_NAME-lxd_preseed_complete.yml >> ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml
cat ./cloud_init_files/multipass_cloud-init_2.yml >> ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml

