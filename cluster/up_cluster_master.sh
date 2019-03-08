#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

CLUSTER_NAME=
BCM_SSH_USERNAME=
BCM_SSH_HOSTNAME=
SSH_KEY_PATH=
BCM_DRIVER=ssh
ENDPOINT_DIR=

for i in "$@"; do
    case $i in
        --cluster-name=*)
            CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --ssh-username=*)
            BCM_SSH_USERNAME="${i#*=}"
            shift # past argument=value
        ;;
        --ssh-hostname=*)
            BCM_SSH_HOSTNAME="${i#*=}"
            shift # past argument=value
        ;;
        --endpoint-dir=*)
            ENDPOINT_DIR="${i#*=}"
            shift # past argument=value
        ;;
        --driver=*)
            BCM_DRIVER="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z "$BCM_SSH_USERNAME" ]]; then
    echo "ERROR: BCM_SSH_USERNAME was not specified. Use --ssh-username="
    exit
fi

if [[ -z "$BCM_SSH_HOSTNAME" ]]; then
    echo "ERROR: BCM_SSH_HOSTNAME was not specified. Use --ssh-hostname="
    exit
fi

if [[ ! -d "$ENDPOINT_DIR" ]]; then
    echo "ERROR: Endpoint directory '$ENDPOINT_DIR' does not exist."
    exit
fi

# if the user override the keypath, we will use that instead.
# the key already exists if it's a multipass VM. If we're provisioning a new
# remote SSH host, we would have to generate a new one.
SSH_KEY_PATH="$ENDPOINT_DIR/id_rsa"
if [[ ! -f $SSH_KEY_PATH ]]; then
    # this key is for temporary use and used only during initial provisioning.
    ssh-keygen -t rsa -b 4096 -C "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" -f "$SSH_KEY_PATH" -N ""
    chmod 400 "$SSH_KEY_PATH.pub"
fi

# if the BCM_DRIVER is multipass, then we assume the remote endpoint doesn't
# exist and we need to create it via multipass. Once there's an SSH service available
# on that endpoint, we can continue.
if [[ $BCM_DRIVER == multipass ]]; then
    # the multipass cloud-init process already has the bcm user provisioned
    bash -c "$BCM_GIT_DIR/cluster/new_multipass_vm.sh --vm-name=$BCM_SSH_HOSTNAME --endpoint-dir=$ENDPOINT_DIR"
    elif [[ $BCM_DRIVER == ssh ]]; then
    ssh-copy-id -i "$SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME"
    # SSH_PUB_KEY_TEXT="$(<$SSH_KEY_PATH.pub)"
    # export SSH_PUB_KEY_TEXT="$SSH_PUB_KEY_TEXT"
    # envsubst < ./ssh_host_init.sh > ./ssh_host_init_temp.sh
    # ssh  "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" 'sudo -n -s bash' < ssh_host_init_temp.sh
    # rm ./ssh_host_init_temp.sh
fi




# # directory on remote host where we're going to work.
# DIR="/home/$BCM_SSH_USERNAME"

# # create the directory on the remote host.
# ssh -i "$BCM_SSH_KEY_PATH" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" -- mkdir -p "$DIR"

# # push the file up to the remote host using SCP
# scp -i "$BCM_SSH_KEY_PATH" ./server_prep.sh "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$DIR/server_prep.sh"

# # change the permissions on the scripts and run it.
# ssh -i "$BCM_SSH_KEY_PATH" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" chmod 0755 "$DIR/server_prep.sh"
# ssh -i "$BCM_SSH_KEY_PATH" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo bash -c "$DIR/server_prep.sh"



# call the following scripts so do a static /etc/hosts mapping since multipass doesn't natively do DNS (or I need more research)
bash -c "$BCM_GIT_DIR/cli/shared/update_controller_etc_hosts.sh"

# let's do an ssh-keyscan so we can get the remote identity added to our BCM_KNOWN_HOSTS_FILE file
ssh-keyscan -H "$VM_NAME" >> "$BCM_KNOWN_HOSTS_FILE"


# first, let's ensure we have SSH access to the server.
if ! wait-for-it -t 30 "$BCM_SSH_HOSTNAME:22"; then
    echo "ERROR: Could not contact the remote machine."
    exit
fi

# shellcheck disable=SC1091
source ./env

# if the user is 'bcm' then we assume the user has been provisioned outside of this
# process.
if [[ $BCM_SSH_USERNAME == "bcm" ]]; then
    REMOTE_MOUNTPOINT='/home/bcm/bcm'
fi

# let's mount the directory via sshfs. This contains the lxd seed file.
./stub_env.sh --master --ssh-username="$BCM_SSH_USERNAME" --ssh-hostname="$BCM_SSH_HOSTNAME" --endpoint-dir="$ENDPOINT_DIR" --driver="$BCM_DRIVER" --cluster-name="$CLUSTER_NAME"

# generate Trezor-backed SSH keys for interactively login.
#SSH_IDENTITY="$BCM_SSH_USERNAME"'@'"$BCM_SSH_HOSTNAME"
bcm ssh newkey --username="$BCM_SSH_USERNAME" --hostname="$BCM_SSH_HOSTNAME" --push --ssh-key-path="$BCM_SSH_KEY_PATH"

# since it's the master, let's grab the certificate so we can use it in subsequent lxd_preseed files.
LXD_CERT_FILE="$ENDPOINT_DIR/lxd.cert"

# makre sure we're on the correct LXC remote
if [[ $(lxc remote get-default) == "$CLUSTER_NAME" ]]; then
    # get the cluster master certificate using LXC.
    touch "$LXD_CERT_FILE"
    lxc info | awk '/    -----BEGIN CERTIFICATE-----/{p=1}p' | sed '1,/    -----END CERTIFICATE-----/!d' | sed "s/^[ \\t]*//" >>"$LXD_CERT_FILE"
fi

#LXD_TOR_HOSTNAME_FILE="$ENDPOINT_DIR/lxd_tor_hostname"
LXD_PRESEED_FILE="$ENDPOINT_DIR/lxd_preseed.yml"

# provision the machine by uploading the preseed and running the install script.
if [[ $BCM_SSH_HOSTNAME == *.onion ]]; then
    torify ssh -i "$BCM_SSH_KEY_PATH" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" -- mkdir -p "$REMOTE_MOUNTPOINT"
    torify scp -i "$BCM_SSH_KEY_PATH" "$LXD_PRESEED_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/lxd_preseed.yml"
    torify scp -i "$BCM_SSH_KEY_PATH" "$BCM_GIT_DIR/cli/commands/install/endpoint_provision.sh" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    torify ssh -i "$BCM_SSH_KEY_PATH" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" chmod 0755 "$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    torify ssh -i "$BCM_SSH_KEY_PATH" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo bash -c "env BCM_WORKING_DIR=$BCM_WORKING_DIR $REMOTE_MOUNTPOINT/endpoint_provision.sh"
    torify wait-for-it -t -30 "$BCM_SSH_HOSTNAME:8443"
else
    ssh -i "$BCM_SSH_KEY_PATH" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" -- mkdir -p "$REMOTE_MOUNTPOINT"
    scp -i "$BCM_SSH_KEY_PATH" "$LXD_PRESEED_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/lxd_preseed.yml"
    scp -i "$BCM_SSH_KEY_PATH" "$BCM_GIT_DIR/cli/commands/install/endpoint_provision.sh" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    ssh -i "$BCM_SSH_KEY_PATH" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" chmod 0755 "$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    ssh -i "$BCM_SSH_KEY_PATH" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo bash -c "$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    wait-for-it -t -30 "$BCM_SSH_HOSTNAME:8443"
fi


# if it's the cluster master add the LXC remote so we can manage it.
if ! lxc remote list --format csv | grep -q "$CLUSTER_NAME"; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    
    echo "Waiting for the remote lxd daemon to become available at $BCM_SSH_HOSTNAME."
    wait-for-it -t 0 "$BCM_SSH_HOSTNAME:8443"
    
    lxc remote add "$CLUSTER_NAME" "$BCM_SSH_HOSTNAME:8443" --accept-certificate --password="$BCM_LXD_SECRET"
    lxc remote switch "$CLUSTER_NAME"
fi

echo "Your new BCM cluster has been created. Your local LXD client is currently configured to target your new cluster."
echo "Consider adding hosts to your new cluster with 'bcm cluster add' (TODO). This helps achieve local high-availability."
echo ""
echo "You can get a remote SSH session by running 'bcm ssh connect --hostname=$BCM_SSH_HOSTNAME --username=$BCM_SSH_USERNAME'"

