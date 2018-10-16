# #!/bin/bash

# # type can be "master" or "member"
# TYPE=$1

# if [ $TYPE != "master" ] && [ $TYPE != "member" ]; then
#     echo "Incorrect usage. Arguments are 'master' and 'member'."    
#     exit
# fi

# NEW_VM_NAME=$BCM_MULTIPASS_VM_NAME

# mkdir -p ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME
# mkdir -p /tmp/bcm
# #touch ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml

# if [ $TYPE = "master" ]; then
#     # Get the IP address that was given to the multipass VM so we can construct the 
#     # cloud-init file.
    

#     # export PRESEED_TEXT=$(cat /tmp/bcm/lxd_master_preseed_tmp.yml)
#     # rm /tmp/bcm/lxd_master_preseed_tmp.yml
#     # envsubst < ./cloud_init/lxd_preseed_template.yml > ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml
# fi

# if [ $TYPE = "member" ]; then
#     echo "running stub-cloud-init got to member section"
#     # let's update our ENV to include the appropriate information from the
#     # LXD cluster master. Grab the info then switch back to the new VM that we're creating.
#     # source ~/.bcm/endpoints/$BCM_LXD_CLUSTER_MASTER.env
#     # export BCM_LXD_CLUSTER_MASTER_PASSWORD=$BCM_LXD_SECRET
#     # source ~/.bcm/endpoints/$NEW_VM_NAME.env

#     # export BCM_LXD_CLUSTER_MASTER_IP=$(multipass list | grep "$BCM_LXD_CLUSTER_MASTER" | awk '{ print $3 }')
#     #export BCM_LXD_CLUSTER_CERTIFICATE=$(cat ~/.bcm/certs/$BCM_LXD_CLUSTER_MASTER/lxd.cert | sed ':a;N;$!ba;s/\n/\n\n/g')

#     # touch /tmp/bcm/cert.txt
#     # echo "-----BEGIN CERTIFICATE-----" > /tmp/bcm/cert.txt
#     # echo "" >> /tmp/bcm/cert.txt
#     # grep -v '\-\-\-\-\-' ~/.bcm/certs/$BCM_LXD_CLUSTER_MASTER/lxd.cert | sed ':a;N;$!ba;s/\n/\n\n/g' | sed 's/^/      /' >> /tmp/bcm/cert.txt
#     # echo "" >> /tmp/bcm/cert.txt
#     # echo "      -----END CERTIFICATE-----" >> /tmp/bcm/cert.txt
#     # echo "" >> /tmp/bcm/cert.txt

#     # export BCM_LXD_CLUSTER_CERTIFICATE=$(cat /tmp/bcm/cert.txt)
#     # envsubst < ./cloud_init/lxd_member_preseed.yml > /tmp/bcm/lxd_member_preseed_tmp.yml
#     # export PRESEED_TEXT=$(cat /tmp/bcm/lxd_member_preseed_tmp.yml)
#     # #rm /tmp/bcm/lxd_member_preseed_tmp.yml
#     # envsubst < ./cloud_init/lxd_preseed_template.yml > ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml

# fi

# #     export BCM_LXD_CLUSTER_MASTER=$2
# #     export BCM_LXD_CLUSTER_MASTER_IP=$(multipass list | grep "$BCM_LXD_CLUSTER_MASTER" | awk '{ print $3 }')
# #     export BCM_LXD_CLUSTER_CERTIFICATE=$(cat ~/.bcm/certs/$BCM_LXD_CLUSTER_MASTER/lxd.cert | sed 's/^/      /' )
# #     source ~/.bcm/endpoints/$BCM_LXD_CLUSTER_MASTER.env
# #     export BCM_LXD_CLUSTER_MASTER_PASSWORD=$BCM_LXD_SECRET
# #     source ~/.bcm/endpoints/$NEW_VM_NAME.env

# #     export BCM_LXD_CLUSTER_CERTIFICATE="$(echo ${BCM_LXD_CLUSTER_CERTIFICATE/$original_string/$string_to_replace})"

# #     envsubst < ./cloud_init/lxd_member_preseed.yml > /tmp/bcm/tmp_lxd_member_preseed.yml
    
    
    
    

# # # | sed ':a;N;$!ba;s/\n/\n\n/g'

# #      #export BCM_LXD_CLUSTER_CERTIFICATE=$(echo ${BCM_LXD_CLUSTER_CERTIFICATE/$GET_RID_OF_TEXT/$NEW_TEXT})
    
# #     #export BCM_MULTIPASS_VM_IP=$(multipass list | grep "$BCM_MULTIPASS_VM_NAME" | awk '{ print $3 }')
    
# #     #printf $"\0" ~/.bcm/certs/$BCM_LXD_CLUSTER_MASTER/lxd.cert
# #     #    # | sed 's/^/    /'
# # fi



# cd ~/.bcm
# git add *
# git commit -am "Added ~/.bcm/runtime/$BCM_MULTIPASS_VM_NAME/cloud-init.yml"
# cd -
