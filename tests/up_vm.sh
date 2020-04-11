#!/bin/bash

set -Eeoux pipefail

BCM_GIT_DIR=$(pwd)

if [[ -z $BCM_BOOTSTRAP_DIR ]]; then
    echo "ERROR: BCM_BOOTSTRAP_DIR IS not defined. Please set your environment."
    exit
fi

if [[ -z $BCM_VM_NAME ]]; then
    echo "ERROR: BCM_VM_NAME IS not defined. Please set your environment ~/.bashrc."
    exit
fi

# # install multipass; all bcm back-end instances exist as multipass vms.
# if [[ ! -f "$(command -v multipass)" ]]; then
#     sudo snap install --edge --classic multipass
# fi

# if ! multipass list | grep -q bcm; then
#     multipass launch --disk="50GB" --mem="4098MB" --cpus="4" --name="$BCM_VM_NAME" daily:20.04
#     #daily:lts
# fi
# if ! lxc network list | grep bcmmacvlan; then
#     lxc network create bcmmacvlan
# fi

# lxc profile device set bcmmacvlan eth0 nictype=macvlan parent="eno1"

# let's make sure we have an ssh keypair for the new vm
if [ ! -f "$HOME/.ssh/$BCM_VM_NAME.local" ]; then
    ssh-keygen -f "$HOME/.ssh/$BCM_VM_NAME.local" -t ecdsa -b 521
fi

# generate the custom cloud-init file. Cloud init installs and configures sshd
SSH_AUTHORIZED_KEY=$(<"$HOME/.ssh/$BCM_VM_NAME.local.pub")
export SSH_AUTHORIZED_KEY="$SSH_AUTHORIZED_KEY"
envsubst <./bcm_vm_lxc_profile.yml >"/tmp/cloud-init.yml"

# let's create a profile for the BCM TYPE-1 VMs. This is per VM.
VM_PROFILE_NAME="$BCM_VM_NAME-vm"
lxc profile create "$VM_PROFILE_NAME"
cat /tmp/cloud-init.yml | lxc profile edit "$VM_PROFILE_NAME"
#rm /tmp/cloud-init.yml

lxc init images:ubuntu/focal/cloud --vm --profile="$VM_PROFILE_NAME" "$BCM_VM_NAME"
#lxc network attach bcmmacvlan "$BCM_VM_NAME" eth0
lxc config device add "$BCM_VM_NAME" eth0 nic nictype=macvlan parent="eno1"
lxc config device add "$BCM_VM_NAME" config disk source=cloud-init:config
lxc start "$BCM_VM_NAME"

sleep 60

IP_V4_ADDRESS=$(lxc list --format csv --columns=4n | grep ",$BCM_VM_NAME" | awk '{print $1;}')
wait-for-it -t 15 "$IP_V4_ADDRESS:22"

# let's get the hosts fingerprint and accept it.
ssh -i "$HOME/.ssh/$BCM_VM_NAME.local.pub" -o "StrictHostKeyChecking no" "ubuntu@$IP_V4_ADDRESS" -- 'sudo mkdir -p "/bcmbootstrap" && sudo chown ubuntu:ubuntu /bcmbootstrap'

#sshfs -i "$HOME/.ssh/$BCM_VM_NAME.local.pub" -o allow_other,default_permissions "ubuntu@$IP_V4_ADDRESS"/bcmbootstrap "$BCM_BOOTSTRAP_DIR"
ssh -i "$HOME/.ssh/$BCM_VM_NAME.local.pub" "ubuntu@$IP_V4_ADDRESS" wget https://raw.githubusercontent.com/BitcoinCacheMachine/BitcoinCacheMachine/dev/init_bcm.sh

ssh -i "$HOME/.ssh/$BCM_VM_NAME.local.pub" "ubuntu@$IP_V4_ADDRESS" chmod 0744 /home/ubuntu/init_bcm.sh

ssh -i "$HOME/.ssh/$BCM_VM_NAME.local.pub" "ubuntu@$IP_V4_ADDRESS" chown ubuntu:ubuntu /home/ubuntu/init_bcm.sh

ssh -i "$HOME/.ssh/$BCM_VM_NAME.local.pub" "ubuntu@$IP_V4_ADDRESS" sudo bash -c /home/ubuntu/init_bcm.sh

ssh -i "$HOME/.ssh/$BCM_VM_NAME.local.pub" "ubuntu@$IP_V4_ADDRESS" bcm deploy

# # make the script executable then run it
# # scripts installs TOR, then git pulls the BCM source code from github
# # TODO 1) move from github to zeronet
# chmod 0744 ./init_bcm.sh
# sudo bash -c ./init_bcm.sh







# # launch the new VM with the custom cloud-init.
# multipass launch --disk="$DISK_SIZE""GB" --mem="$MEM_SIZE" --cpus="$CPU_COUNT" --name="$VM_NAME" --cloud-init "$BCM_TMP_DIR/cloud-init.yml" bionic
# rm "$BCM_TMP_DIR/cloud-init.yml"

# multipass copy-files ./server_prep.sh "$VM_NAME:/home/multipass/server_prep.sh"

# multipass exec "$VM_NAME"  -- chmod 0755 /home/multipass/server_prep.sh
# multipass exec "$VM_NAME"  -- bash -c /home/multipass/server_prep.sh

# # let's get the onion address and add it as a bcm-onion site. This is a management plane admin interface.
# MGMT_PLANE_ONION_ADDRESS="$(multipass exec "$VM_NAME" -- sudo cat /var/lib/tor/ssh/hostname)"
# if [[ ! -z $MGMT_PLANE_ONION_ADDRESS ]]; then
#     touch "$ENDPOINT_DIR/mgmt-onion.env"
#     {
#         echo "#!/bin/bash"
#         echo "$MGMT_PLANE_ONION_ADDRESS"
#     } >> "$ENDPOINT_DIR/mgmt-onion.env"
# fi

# multipass restart "$VM_NAME"

# IPV4_ADDRESS=$(multipass list --format csv | grep $VM_NAME | awk -F "\"*,\"*" '{print $3}')
# if [[ ! -z $IPV4_ADDRESS && ! -z $VM_NAME ]]; then
#     echo "$IPV4_ADDRESS    $VM_NAME" | sudo tee -a /etc/hosts
# fi

# # let's do an ssh-keyscan so we can get the remote identity added to our BCM_KNOWN_HOSTS_FILE file
# ssh-keyscan -H "$VM_NAME" >> "$BCM_KNOWN_HOSTS_FILE"

# rm -rf "$ENDPOINT_DIR/cloud-init.yml"


















# lxc exec "$BCM_VM_NAME" -- apt-get update && sudo apt-get install -y sshfs openssh-server
#lxc file push ./vm_ssh_config "$BCM_VM_NAME":/etc/ssh/ssh_config
#lxc exec "$BCM_VM_NAME" -- sudo chown root:root /etc/ssh/ssh_config && sudo systemctl restart ssh


#Ciphers aes128-ctr,aes192-ctr,aes256-ctr
#HostKeyAlgorithms ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,ssh-rsa,ssh-dss
#KexAlgorithms ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha256
#MACs hmac-sha2-256,hmac-sha2-512,hmac-sha1



# multipass exec "$BCM_VM_NAME" -- apt-get update && apt-get install -y sshfs

# multipass exec "$BCM_VM_NAME" -- mkdir -p /usr/local/bin
# multipass exec "$BCM_VM_NAME" -- mkdir -p /home/ubuntu/.bcmbootstrap

# multipass mount "$BCM_GIT_DIR"/../ "$BCM_VM_NAME:/usr/local/bin"
# multipass mount "$BCM_BOOTSTRAP_DIR"/../ "$BCM_VM_NAME:/home/ubuntu/.bcmbootstrap"

# # since we are mounting the BCM_GIT_DIR using multipass, we will do a tor-only bcm_init
# multipass exec "$BCM_VM_NAME" -- sudo bash -c /usr/local/bin/init_bcm.sh --tor-only

# # run the install script.
# multipass exec "$BCM_VM_NAME" -- sudo bash -c /usr/local/bin/install.sh

# multipass exec "$BCM_VM_NAME" -- bcm deploy
