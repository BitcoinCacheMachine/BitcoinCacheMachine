#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_HELP_FLAG=0

VALUE=${2:-}
if [ ! -z "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a cluster command."
    cat ./help.txt
    exit
fi

if ! snap list | grep -q lxd; then
    bash -c "$BCM_GIT_DIR/cli/commands/install/snap_install_lxd_local.sh"
fi

CLUSTER_NAME=$(lxc remote get-default)
BCM_ENDPOINTS_FLAG=0
BCM_DRIVER=
BCM_SSH_HOSTNAME=
BCM_SSH_USERNAME=
MACVLAN_INTERFACE=

for i in "$@"; do
    case $i in
        --driver=*)
            BCM_DRIVER="${i#*=}"
            shift # past argument=value
        ;;
        --cluster-name=*)
            CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --ssh-hostname=*)
            BCM_SSH_HOSTNAME="${i#*=}"
            shift # past argument=value
        ;;
        --ssh-username=*)
            BCM_SSH_USERNAME="${i#*=}"
            shift # past argument=value
        ;;
        --endpoints)
            BCM_ENDPOINTS_FLAG=1
            shift # past argument=value
        ;;
        *) ;;
        
    esac
done

if [[ $BCM_HELP_FLAG == 1 ]]; then
    cat ./help.txt
    exit
fi

if [[ "$BCM_CLI_VERB" == "list" ]]; then
    if [[ $BCM_ENDPOINTS_FLAG == 1 ]]; then
        lxc cluster list | grep "$CLUSTER_NAME" | awk '{print $2}'
        exit
    fi
    
    lxc remote list --format csv | grep "bcm-" | awk -F "," '{print $1}' | awk '{print $1}'
    
    exit
fi

if [[ $BCM_CLI_VERB == "create" ]]; then
    # ensure we have trezor-backed certificates and password store
    bcm init
    
    # if the user didn't specify a driver, let's ask them how we want to proceed.
    # find out if they want a bare-metal or multipass-based deployment.
    if [[ -z $BCM_DRIVER ]]; then
        CONTINUE=0
        while [[ "$CONTINUE" == 0 ]]
        do
            echo "Would you like to deploy BCM locally, a hardware-based VM (more secure), or to a remote SSH endpoint?"
            read -rp "(vm/local/ssh):  "   CHOICE
            
            if [[ "$CHOICE" == "vm" ]]; then
                CONTINUE=1
                # Check to see if the computer has hardware virtualization support. If not, then we
                # switch our driver to SSH.
                if ! lscpu | grep "Virtualization:" | cut -d ":" -f 2 | xargs | grep -q "VT-x"; then
                    echo "Your computer does NOT support hardware virtualization. You may need to turn this feature on in the BIOS."
                    echo "Consider deploying BCM  in a bare-metal configuration."
                    exit
                fi
                
                # the cloud-init file for multipass uses 'bcm' as the username.
                BCM_DRIVER=multipass
                BCM_SSH_USERNAME="bcm"
                CLUSTER_NAME="bcm-$(hostname)"
                BCM_SSH_HOSTNAME="$CLUSTER_NAME-01"
                MACVLAN_INTERFACE="ens3"
                
                # Next make sure multipass is installed so we can run type-1 VMs
                if ! snap list | grep -q multipass; then
                    # if it doesn't, let's install
                    echo "Performing a local LXD installation using multipass. Note this provides no fault tolerance."
                    sudo snap install multipass --beta --classic
                    sleep 10
                fi
                
                elif [[ "$CHOICE" == "local" ]]; then
                CONTINUE=1
                BCM_DRIVER=baremetal
                CLUSTER_NAME="bcm-$(hostname)"
                BCM_SSH_HOSTNAME="$CLUSTER_NAME-01"
                BCM_SSH_USERNAME="$(whoami)"
                
                # let's add an alias in /etc/hosts so the SDN controller can resolve 'bcm-$(hostname)-01'
                HOSTS_ENTRY="127.0.1.1    $BCM_SSH_HOSTNAME"
                if ! grep -Fxq "$HOSTS_ENTRY" /etc/hosts; then
                    echo "$HOSTS_ENTRY" | sudo tee -a /etc/hosts
                fi
                
                elif [[ "$CHOICE" == "ssh" ]]; then
                CONTINUE=1
                BCM_DRIVER=ssh
                BCM_SSH_HOSTNAME=
                BCM_SSH_USERNAME=
                
                echo "Please enter the DNS-resolveable hostname of the remote SSH endpoint you want to deploy BCM to:  "
                read -rp "SSH Hostname:  "   BCM_SSH_HOSTNAME
                wait-for-it -t 15 "$BCM_SSH_HOSTNAME:22"
                
                echo "Please enter the username that has administrative privilieges on $BCM_SSH_HOSTNAME"
                read -rp "SSH username:  "   BCM_SSH_USERNAME
                
                
                CLUSTER_NAME="bcm-$BCM_SSH_HOSTNAME"
            else
                echo "Invalid entry. Please try again."
            fi
        done
    fi
    
    # let's ask the user which network interface they want to expose BCM services on
    if [[ -z $MACVLAN_INTERFACE ]]; then
        echo "Please enter the network interface you want to expose BCM services on: "
        read -rp "Network Interface:  "   MACVLAN_INTERFACE
    fi
    
    # if the cluster name is local, then we assume the user hasn't overridden
    # what was set in 'lxc remote get-default'. If so, we will assume a cluster
    # will be created with the name of `bcm-hostname`
    
    if bcm cluster list | grep -q "$CLUSTER_NAME"; then
        echo "The BCM Cluster '$CLUSTER_NAME' already exists!"
        exit
    fi
    
    CLUSTER_DIR="$BCM_WORKING_DIR/$CLUSTER_NAME"
    ENDPOINT_DIR="$CLUSTER_DIR/$BCM_SSH_HOSTNAME"
    mkdir -p "$ENDPOINT_DIR"
    
    # first check to ensure that the cluster doesn't already exist.
    if ! lxc remote list | grep -q "$CLUSTER_NAME"; then
        export REMOTE_MOUNTPOINT="/tmp/provisioning"
        
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
            elif [[ $BCM_DRIVER == ssh || $BCM_DRIVER == baremetal ]]; then
            ssh-copy-id -i "$SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME"
        fi
        
        # let's do an ssh-keyscan so we can get the remote identity added to our BCM_KNOWN_HOSTS_FILE file
        ssh-keyscan -H "$BCM_SSH_HOSTNAME" >> "$BCM_KNOWN_HOSTS_FILE"
        
        # first, let's ensure we have SSH access to the server.
        if ! wait-for-it -t 30 "$BCM_SSH_HOSTNAME:22"; then
            echo "ERROR: Could not contact the remote machine."
            exit
        fi
        
        
        # if the user is 'bcm' then we assume the user has been provisioned outside of this process.
        if [[ $BCM_SSH_USERNAME == "bcm" ]]; then
            REMOTE_MOUNTPOINT='/home/bcm/bcm'
        fi
        
        bash -c "$BCM_GIT_DIR/cluster/stub_env.sh --master --ssh-username=$BCM_SSH_USERNAME --ssh-hostname=$BCM_SSH_HOSTNAME --endpoint-dir=$ENDPOINT_DIR --driver=$BCM_DRIVER --cluster-name=$CLUSTER_NAME --macvlan-interface=$MACVLAN_INTERFACE"
        
        # generate Trezor-backed SSH keys for interactively login.
        bcm ssh newkey --username="$BCM_SSH_USERNAME" --hostname="$BCM_SSH_HOSTNAME" --endpoint-dir="$ENDPOINT_DIR" --push --ssh-key-path="$SSH_KEY_PATH"
        
        LXD_PRESEED_FILE="$ENDPOINT_DIR/lxd_preseed.yml"
        
        # provision the machine by uploading the preseed and running the install script.
        ssh -i "$SSH_KEY_PATH" -t -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" -- mkdir -p "$REMOTE_MOUNTPOINT"
        scp -i "$SSH_KEY_PATH"  -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$LXD_PRESEED_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/lxd_preseed.yml"
        scp -i "$SSH_KEY_PATH"  -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$BCM_GIT_DIR/cli/commands/install/endpoint_provision.sh" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/endpoint_provision.sh"
        ssh -i "$SSH_KEY_PATH"  -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" chmod 0755 "$REMOTE_MOUNTPOINT/endpoint_provision.sh"
        ssh -i "$SSH_KEY_PATH"  -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo bash -c "$REMOTE_MOUNTPOINT/endpoint_provision.sh"
        wait-for-it -t -30 "$BCM_SSH_HOSTNAME:8443"
        
        # if it's the cluster master add the LXC remote so we can manage it.
        if ! lxc remote list --format csv | grep -q "$CLUSTER_NAME"; then
            echo "Waiting for the remote lxd daemon to become available at $BCM_SSH_HOSTNAME."
            wait-for-it -t 10 "$BCM_SSH_HOSTNAME:8443"
            
            source "$ENDPOINT_DIR/env"
            lxc remote add "$CLUSTER_NAME" "$BCM_SSH_HOSTNAME:8443" --accept-certificate --password="$BCM_LXD_SECRET"
            lxc remote switch "$CLUSTER_NAME"
            
            # since it's the master, let's grab the certificate so we can use it in subsequent lxd_preseed files.
            LXD_CERT_FILE="$ENDPOINT_DIR/lxd.cert"
            
            # make sure we're on the correct LXC remote
            if [[ $(lxc remote get-default) == "$CLUSTER_NAME" ]]; then
                # get the cluster master certificate using LXC.
                touch "$LXD_CERT_FILE"
                lxc info | awk '/    -----BEGIN CERTIFICATE-----/{p=1}p' | sed '1,/    -----END CERTIFICATE-----/!d' | sed "s/^[ \\t]*//" >>"$LXD_CERT_FILE"
            fi
        fi
        
        echo "Your new BCM cluster has been created. Your local LXD client is currently configured to target your new cluster."
        echo "Consider adding hosts to your new cluster with 'bcm cluster add' (TODO). This helps achieve local high-availability."
        echo ""
        echo "You can get a remote SSH session by running 'bcm ssh connect --hostname=$BCM_SSH_HOSTNAME --username=$BCM_SSH_USERNAME'"
        
    else
        echo "ERROR: BCM cluster '$CLUSTER_NAME' already exists!"
        exit
    fi
fi

if [[ $BCM_CLI_VERB == "destroy" ]]; then
    if [[ $CLUSTER_NAME != "local" ]]; then
        CONTINUE=0
        while [[ "$CONTINUE" == 0 ]]
        do
            echo "WARNING: Are you sure you want to delete the current cluster '$CLUSTER_NAME'? This will DESTROY ALL DATA!!!"
            read -rp "Are you sure (y/n):  "   CHOICE
            
            if [[ "$CHOICE" == "y" ]]; then
                CONTINUE=1
                elif [[ "$CHOICE" == "n" ]]; then
                exit
            else
                echo "Invalid entry. Please try again."
            fi
        done
    fi
    
    # TODO ITERATE OVER FOLDERS IN CLUSTER FOLDER AND DELETE BASED ON env.
    CLUSTER_DIR="$BCM_WORKING_DIR/$CLUSTER_NAME"
    
    if [[ -d $CLUSTER_DIR ]]; then
        for ENDPOINT_DIR in $(find "$CLUSTER_DIR" -mindepth 1 -maxdepth 1 -type d); do
            if [[ -f $ENDPOINT_DIR/env ]]; then
                source "$ENDPOINT_DIR/env"
                
                if [[ $BCM_DRIVER == multipass ]]; then
                    BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME"
                    if multipass list | grep -q "$BCM_SSH_HOSTNAME"; then
                        multipass stop "$BCM_SSH_HOSTNAME"
                        multipass delete "$BCM_SSH_HOSTNAME"
                        multipass purge
                    fi
                    
                    # remove the entry for the host in your BCM_KNOWN_HOSTS_FILE
                    ssh-keygen -f "$BCM_KNOWN_HOSTS_FILE" -R "$BCM_SSH_HOSTNAME" >> /dev/null
                    
                    # clear any relevant /etc/host entries (and remove extra lines)
                    sudo sed -i '/^$BCM_SSH_HOSTNAME/d' /etc/hosts
                fi
                
                # clearing all lines from /etc/hosts that contain "$BCM_SSH_HOSTNAME"
                sudo sed -i "/$BCM_SSH_HOSTNAME/d" /etc/hosts
                sudo sed -i '/^$/d' /etc/hosts
            fi
        done
        
        if [[ $CHOICE == "y" ]]; then
            # delete the cluster directory
            rm -rf "${CLUSTER_DIR:?}"
        fi
    fi
    
    if [[ $CLUSTER_NAME != "local" ]]; then
        if [[ $(lxc remote get-default) != "local" ]]; then
            # if it's the cluster master add the LXC remote so we can manage it.
            if lxc remote list --format csv | grep -q "$CLUSTER_NAME"; then
                echo "Switching lxd remote to local."
                lxc remote switch "local"
                
                echo "Removing lxd remote for cluster '$CLUSTER_NAME'."
                lxc remote remove "$CLUSTER_NAME"
            fi
        fi
    fi
fi