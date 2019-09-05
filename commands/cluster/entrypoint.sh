#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE=${2:-}
if [ ! -z "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a cluster command."
    cat ./help.txt
    exit
fi

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
            BCM_CLUSTER_NAME="${i#*=}"
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
        endpoints)
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
        lxc cluster list | grep "$BCM_CLUSTER_NAME" | awk '{print $2}'
        exit
    fi
    
    lxc remote list --format csv | grep "bcm-" | awk -F "," '{print $1}' | awk '{print $1}'
    exit
fi

if [[ $BCM_CLI_VERB == "create" ]]; then
    MACVLAN_INTERFACE=
    
    if [[ ! -d "$GNUPGHOME/trezor" ]]; then
        # ensure we have trezor-backed certificates and password store
        bcm init
    fi
    
    DEPLOYMENT_METHODS="local/ssh"
    SUPPORTS_VIRTUALIZATION=0
    if lscpu | grep "Virtualization:" | cut -d ":" -f 2 | xargs | grep -q "VT-x"; then
        DEPLOYMENT_METHODS="$DEPLOYMENT_METHODS/vm"
        SUPPORTS_VIRTUALIZATION=1
    fi
    
    # if the user didn't specify a driver, let's ask them how we want to proceed.
    # find out if they want a "local" or multipass-based deployment.
    if [[ -z $BCM_DRIVER ]]; then
        CONTINUE=0
        while [[ "$CONTINUE" == 0 ]]; do
            echo "How would you like to deploy your backend? VM is good for testing and development, but can't"
            echo "expose BCM services on your LAN. Local deployments are usually a good choice, but BCM does make"
            echo "some modifications to your system. Usually the best option is ssh, which allows you to run BCM"
            echo "on a dedicated machine."
            echo ""
            read -rp "Deployment method ($DEPLOYMENT_METHODS):  " CHOICE
            
            if [[ "$CHOICE" == "vm" ]]; then
                CONTINUE=1
                
                # the cloud-init file for multipass uses 'bcm' as the username.
                BCM_DRIVER=multipass
                BCM_SSH_USERNAME="bcm"
                BCM_CLUSTER_NAME="bcm-multipass"
                BCM_SSH_HOSTNAME="$BCM_CLUSTER_NAME-01"
                MACVLAN_INTERFACE="ens3"
                
                # Next make sure multipass is installed so we can run type-1 VMs
                if [ ! -x "$(command -v multipass)" ]; then
                    # let's check to make sure we have multipass. This check to ensure we support
                    # virtualizatin, then check to see if multipass is installed; if not, we install it
                    if [[ $SUPPORTS_VIRTUALIZATION == 1 ]]; then
                        if [ ! -x "$(command -v multipass)" ]; then
                            echo "Info: installing multipass."
                            sudo snap install multipass --beta --classic
                            sleep 5
                        fi
                        
                        if multipass list | grep -q "$BCM_CLUSTER_NAME-01"; then
                            multipass stop "$BCM_CLUSTER_NAME-01"
                            multipass delete "$BCM_CLUSTER_NAME-01"
                            multipass purge
                        fi
                    fi
                fi
                elif [[ "$CHOICE" == "ssh" ]]; then
                CONTINUE=1
                BCM_DRIVER=ssh
                BCM_SSH_HOSTNAME=
                BCM_SSH_USERNAME=
                
                echo "Please enter the DNS-resolveable hostname of the remote SSH endpoint you want to deploy BCM to:  "
                read -rp "SSH Hostname:  " BCM_SSH_HOSTNAME
                wait-for-it -t 15 "$BCM_SSH_HOSTNAME:22"
                
                BCM_SSH_USERNAME=ubuntu
                echo "Please enter the username that has administrative privileges on $BCM_SSH_HOSTNAME"
                read -rp "SSH username (default: $BCM_SSH_USERNAME):  " BCM_SSH_USERNAME
                
                if [[ -z $BCM_SSH_USERNAME ]]; then
                    BCM_SSH_USERNAME=ubuntu
                fi
                
                BCM_CLUSTER_NAME="bcm-$BCM_SSH_HOSTNAME"
                elif [[ "$CHOICE" == "local" ]]; then
                CONTINUE=1
                BCM_DRIVER="local"
                BCM_CLUSTER_NAME="local"
                BCM_SSH_HOSTNAME="local"
                BCM_SSH_USERNAME="$(whoami)"
                
                # since we're doing a local install; we can just connect our wirepoint
                # endpoint listening service on the same interface being used for our
                # default route. TODO; add CLI option to specify address.
                MACVLAN_INTERFACE="$(ip route | grep default | cut -d " " -f 5)"
            fi
        done
    fi
    
    # let's ask the user which network interface they want to expose BCM services on
    if [[ -z $MACVLAN_INTERFACE ]]; then
        echo "Please enter the network interface you want to expose BCM services on: "
        read -rp "Network Interface:  " MACVLAN_INTERFACE
    fi
    
    ENDPOINT_DIR_TEMP="$BCM_SSH_HOSTNAME"
    
    # make sure we convert the endpoint directory to proper naming conventions.
    # this might be the case if we have an ssh endpoint.
    if [[ "$ENDPOINT_DIR_TEMP" != *-01 ]]; then
        ENDPOINT_DIR_TEMP="$ENDPOINT_DIR_TEMP-01"
    fi
    
    if [[ "$ENDPOINT_DIR_TEMP" != bcm* ]]; then
        ENDPOINT_DIR_TEMP="bcm-$ENDPOINT_DIR_TEMP"
    fi
    
    ENDPOINT_DIR="$BCM_CLUSTER_DIR/$ENDPOINT_DIR_TEMP"
    
    mkdir -p "$ENDPOINT_DIR"
    
    # let's stub out the lxd_preseed file.
    ./stub_env.sh --master \
    --ssh-username="$BCM_SSH_USERNAME" \
    --ssh-hostname="$BCM_SSH_HOSTNAME" \
    --endpoint-dir="$ENDPOINT_DIR" \
    --driver="$BCM_DRIVER" \
    --cluster-name="$BCM_CLUSTER_NAME" \
    --macvlan-interface="$MACVLAN_INTERFACE"
    
    LXD_PRESEED_FILE="$ENDPOINT_DIR/lxd_preseed.yml"
    if [[ $BCM_DRIVER == "local" ]]; then
        echo "Updating your system and installing prerequisities."
        sudo bash -c "$BCM_GIT_DIR/commands/install/endpoint_provision.sh --preseed-path=$LXD_PRESEED_FILE"
        lxc remote set-default "local"
    fi
    
    # # first check to ensure that the cluster doesn't already exist.
    # if ! lxc remote list | grep -q "$BCM_CLUSTER_NAME"; then
    #     export REMOTE_MOUNTPOINT="/tmp/bcm"
    
    #     # if the user override the keypath, we will use that instead.
    #     # the key already exists if it's a multipass VM. If we're provisioning a new
    #     # remote SSH host, we would have to generate a new one.
    #     SSH_KEY_PATH="$ENDPOINT_DIR/id_rsa"
    #     if [[ ! -f $SSH_KEY_PATH ]]; then
    #         # this key is for temporary use and used only during initial provisioning.
    #         ssh-keygen -t rsa -b 4096 -C "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" -f "$SSH_KEY_PATH" -N ""
    #         chmod 400 "$SSH_KEY_PATH.pub"
    #     fi
    
    #     # if the BCM_DRIVER is multipass, then we assume the remote endpoint doesn't
    #     # exist and we need to create it via multipass. Once there's an SSH service available
    #     # on that endpoint, we can continue.
    #     if [[ $BCM_DRIVER == multipass ]]; then
    #         # the multipass cloud-init process already has the bcm user provisioned
    #         ./new_multipass_vm.sh --vm-name="$BCM_SSH_HOSTNAME" --endpoint-dir="$ENDPOINT_DIR"
    #         elif [[ $BCM_DRIVER == ssh || $BCM_DRIVER == "local" ]]; then
    #         ssh-copy-id -i "$SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME"
    #     fi
    
    #     # let's do an ssh-keyscan so we can get the remote identity added to our BCM_KNOWN_HOSTS_FILE file
    #     ssh-keyscan -H "$BCM_SSH_HOSTNAME" >>"$BCM_KNOWN_HOSTS_FILE"
    
    #     # first, let's ensure we have SSH access to the server.
    #     if ! wait-for-it -t 30 "$BCM_SSH_HOSTNAME:22"; then
    #         echo "Error: Could not contact the remote machine."
    #         exit
    #     fi
    
    #     # if the user is 'bcm' then we assume the user has been provisioned outside of this process.
    #     if [[ $BCM_SSH_USERNAME == "bcm" ]]; then
    #         REMOTE_MOUNTPOINT='/home/bcm/bcm'
    #     fi
    
    #     # generate Trezor-backed SSH keys for interactively login.
    #     bash -c "$BCM_GIT_DIR/commands/ssh/entrypoint.sh --username=$BCM_SSH_USERNAME --hostname=$BCM_SSH_HOSTNAME --endpoint-dir=$ENDPOINT_DIR --push --ssh-key-path=$SSH_KEY_PATH"
    
    #     LXD_PRESEED_FILE="$ENDPOINT_DIR/lxd_preseed.yml"
    
    #     # provision the machine by uploading the preseed and running the install script.
    #     ssh -i "$SSH_KEY_PATH" -t -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" -- mkdir -p "$REMOTE_MOUNTPOINT"
    #     scp -i "$SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$LXD_PRESEED_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/lxd_preseed.yml"
    #     scp -i "$SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" "$BCM_GIT_DIR/commands/install/endpoint_provision.sh" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    #     ssh -i "$SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" chmod 0755 "$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    #     ssh -i "$SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo bash -c "$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    
    #     wait-for-it -t -30 "$BCM_SSH_HOSTNAME:8443"
    #     wait-for-it -t -30 "$BCM_SSH_HOSTNAME:22"
    
    #     ssh -i "$SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" rm -rf "$REMOTE_MOUNTPOINT"
    
    #     # ibcmf it's the cluster master add the LXC remote so we can manage it.
    #     if ! lxc remote list --format csv | grep -q "$BCM_CLUSTER_NAME"; then
    #         echo "Waiting for the remote lxd daemon to become available at $BCM_SSH_HOSTNAME."
    #         wait-for-it -t 10 "$BCM_SSH_HOSTNAME:8443"
    
    #         # shellcheck source=$ENDPOINT_DIR/env
    #         source "$ENDPOINT_DIR/env"
    #         lxc remote add "$BCM_CLUSTER_NAME" "$BCM_SSH_HOSTNAME:8443" --accept-certificate --password="$BCM_LXD_SECRET"
    #         lxc remote switch "$BCM_CLUSTER_NAME"
    
    #         # since it's the master, let's grab the certificate so we can use it in subsequent lxd_preseed files.
    #         LXD_CERT_FILE="$ENDPOINT_DIR/lxd.cert"
    
    #         # make sure we're on the correct LXC remote
    #         if [[ $(lxc remote get-default) == "$BCM_CLUSTER_NAME" ]]; then
    #             # get the cluster master certificate using LXC.
    #             touch "$LXD_CERT_FILE"
    #             lxc info | awk '/    -----BEGIN CERTIFICATE-----/{p=1}p' | sed '1,/    -----END CERTIFICATE-----/!d' | sed "s/^[ \\t]*//" >>"$LXD_CERT_FILE"
    #         fi
    #     fi
    
    #     echo "Your new BCM cluster has been created. Your local LXD client is currently configured to target your new cluster."
    #     echo "You can get a remote SSH session by running 'bcm ssh connect --hostname=$BCM_SSH_HOSTNAME --username=$BCM_SSH_USERNAME'"
    
    # else
    #     echo "Error: BCM cluster '$BCM_CLUSTER_NAME' already exists!"
    #     exit
    # fi
fi

# this is where we implement 'bcm cluster destroy'
if [[ $BCM_CLI_VERB == "clear" ]]; then
    # TODO convert this to git and reference the upstream repo script. https://github.com/lxc/lxd/blob/master/scripts/empty-lxd.sh
    CONTINUE=0
    while [[ "$CONTINUE" == 0 ]]; do
        echo "WARNING: Are you sure you want to delete all LXD objects from cluster '$BCM_CLUSTER_NAME'? This will DESTROY ALL DATA!!!"
        read -rp "Are you sure (y/n):  " CHOICE
        
        if [[ "$CHOICE" == "y" ]]; then
            CONTINUE=1
            # let's ensure our remote git repo is updated.
            # TODO move this over a TOR connection via PROXY switch/config.
            # TODO ensure we're using an encrypted storage backend for all /tmp/bcm files
            
            mkdir -p /tmp/bcm
            rm -f /tmp/bcm/empty-lxd.sh
            wget -O /tmp/bcm/empty-lxd.sh https://raw.githubusercontent.com/lxc/lxd/master/scripts/empty-lxd.sh
            chmod 0755 /tmp/bcm/empty-lxd.sh
            bash -c /tmp/bcm/empty-lxd.sh
            rm -f /tmp/bcm/empty-lxd.sh
            
            elif [[ "$CHOICE" == "n" ]]; then
            echo "Info:  Aborted 'bcm cluster clear' command."
            exit
        else
            echo "Invalid entry. Please try again."
        fi
    done
fi

# this is where we implement 'bcm cluster destroy'
if [[ $BCM_CLI_VERB == "destroy" ]]; then
    
    # TODO ITERATE OVER FOLDERS IN CLUSTER FOLDER AND DELETE BASED ON env.
    CLUSTER_DIR="$BCM_CLUSTERS_DIR/$BCM_CLUSTER_NAME"
    
    if [[ -d $CLUSTER_DIR ]]; then
        CONTINUE=0
        while [[ "$CONTINUE" == 0 ]]; do
            echo "WARNING: Are you sure you want to delete the current cluster '$BCM_CLUSTER_NAME'? This will DESTROY ALL DATA!!!"
            read -rp "Are you sure (y/n):  " CHOICE
            
            if [[ "$CHOICE" == "y" ]]; then
                CONTINUE=1
                elif [[ "$CHOICE" == "n" ]]; then
                exit
            else
                echo "Invalid entry. Please try again."
            fi
        done
        
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
                    ssh-keygen -f "$BCM_KNOWN_HOSTS_FILE" -R "$BCM_SSH_HOSTNAME" >>/dev/null
                    
                    # clear any relevant /etc/host entries (and remove extra lines)
                    sudo sed -i '/^$BCM_SSH_HOSTNAME/d' /etc/hosts
                    elif [[ $BCM_DRIVER == ssh ]]; then
                    
                    SSH_KEY_PATH="$ENDPOINT_DIR/id_rsa"
                    
                    ssh -i "$SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo lxd shutdown
                    ssh -i "$SSH_KEY_PATH" -o UserKnownHostsFile="$BCM_KNOWN_HOSTS_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo snap remove lxd
                    elif [[ $BCM_DRIVER == "local" ]]; then
                    
                    if [ -x "$(command -v lxc)" ]; then
                        sudo lxd shutdown
                        sudo lxd init --auto --network-address=127.0.0.1 --network-port=8443
                    else
                        echo "Info: lxd was not installed."
                    fi
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
    
    if [ -x "$(command -v multipass)" ]; then
        if multipass list | grep -q "$BCM_CLUSTER_NAME-01"; then
            multipass stop "$BCM_CLUSTER_NAME-01"
            multipass delete "$BCM_CLUSTER_NAME-01"
            multipass purge
        fi
    fi
    
    if lxc remote list --format csv | grep -q "$BCM_CLUSTER_NAME"; then
        bcm cluster clear
        
        # if it's the cluster master add the LXC remote so we can manage it.
        echo "Switching lxd remote to local."
        lxc remote switch "local"
        
        if [[ $BCM_CLUSTER_NAME != "local" ]]; then
            echo "Removing lxd remote for cluster '$BCM_CLUSTER_NAME'."
            lxc remote remove "$BCM_CLUSTER_NAME"
        else
            sudo snap remove lxd
        fi
    else
        echo "WARNING: The active cluster is not set! Nothing to destroy. Consider adding --cluster-name= to specify a cluster."
    fi
fi
