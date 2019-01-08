#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

IS_MASTER=0
BCM_CLUSTER_ENDPOINT_NAME=
BCM_PROVIDER_NAME=
BCM_CLUSTER_ENDPOINT_DIR=
BCM_ENDPOINT_VM_IP=

for i in "$@"; do
	case $i in
	--master)
		IS_MASTER=1
		shift # past argument=value
		;;
	--cluster-name=*)
		BCM_CLUSTER_NAME="${i#*=}"
		shift # past argument=value
		;;
	--endpoint-name=*)
		BCM_CLUSTER_ENDPOINT_NAME="${i#*=}"
		shift # past argument=value
		;;
	--provider=*)
		BCM_PROVIDER_NAME="${i#*=}"
		shift # past argument=value
		;;
	--endpoint-dir=*)
		BCM_CLUSTER_ENDPOINT_DIR="${i#*=}"
		shift # past argument=value
		;;
	*)
		# unknown option
		;;
	esac
done

echo "IS_MASTER: $IS_MASTER"
echo "BCM_CLUSTER_ENDPOINT_NAME: $BCM_CLUSTER_ENDPOINT_NAME"
echo "BCM_PROVIDER_NAME: $BCM_PROVIDER_NAME"
echo "BCM_CLUSTER_ENDPOINT_DIR: $BCM_CLUSTER_ENDPOINT_DIR"
echo "BCM_CLUSTER_ENDPOINT_DIR: $BCM_CLUSTER_ENDPOINT_DIR"
echo "BCM_SSH_HOSTNAME: $BCM_SSH_HOSTNAME"
echo "BCM_SSH_USERNAME: $BCM_SSH_USERNAME"

# if there's no .env file for the specified VM, we'll generate a new one.
if [ -f $BCM_CLUSTER_ENDPOINT_DIR/.env ]; then
	# shellcheck source=/dev/null
	source "$BCM_CLUSTER_ENDPOINT_DIR/.env"
else
	echo "Error. No $BCM_CLUSTER_ENDPOINT_DIR/.env file to source."
	exit
fi

if [[ -z $BCM_PROVIDER_NAME ]]; then
	echo "BCM_PROVIDER_NAME not set. Exiting."
	exit
fi

# prepare the cloud-init file
if [[ $BCM_PROVIDER_NAME != "local" ]]; then
	if [[ -f $BCM_CLUSTER_ENDPOINT_DIR/lxd_preseed.yml ]]; then
		BCM_CLUSTER_MASTER_LXD_PRESEED=$(awk '{print "      " $0}' "$BCM_CLUSTER_ENDPOINT_DIR/lxd_preseed.yml")
		export BCM_CLUSTER_MASTER_LXD_PRESEED

		BCM_LISTEN_INTERFACE=
		if [[ $BCM_PROVIDER_NAME == "multipass" ]]; then
			BCM_LISTEN_INTERFACE=ens3
		fi

		export BCM_LISTEN_INTERFACE=$BCM_LISTEN_INTERFACE
		envsubst <./cloud_init_template.yml >$BCM_CLUSTER_ENDPOINT_DIR/cloud-init.yml
	fi
fi

if [[ $BCM_PROVIDER_NAME == "multipass" ]]; then
	## launch the VM based with a static cloud-init.
	# we'll create lxd preseed files AFTER boot so we know the IP address.
	multipass launch \
		--disk "$BCM_ENDPOINT_DISK_SIZE" \
		--mem "$BCM_ENDPOINT_MEM_SIZE" \
		--cpus "$BCM_ENDPOINT_CPU_COUNT" \
		--name "$BCM_CLUSTER_ENDPOINT_NAME" \
		--cloud-init "$BCM_CLUSTER_ENDPOINT_DIR/cloud-init.yml" \
		cosmic
fi

if [[ $BCM_PROVIDER_NAME == "ssh" ]]; then
	# let's mount the directory via sshfs. This contains the lxd seed file.
	REMOTE_MOUNTPOINT="/home/$BCM_SSH_USERNAME/bcm"
	SSH_KEY_FILE="$BCM_ENDPOINT_DIR/id_rsa"

	ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" mkdir -p "$REMOTE_MOUNTPOINT"
	scp -i "$SSH_KEY_FILE" "$BCM_ENDPOINT_DIR/lxd_preseed.yml" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/lxd_preseed.yml"
	scp -i "$SSH_KEY_FILE" "$BCM_GIT_DIR/cli/commands/install/snap_lxd_install.sh" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/provision.sh"

	# run the snap_install script on the remote host.
	ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" -- sudo bash -c "$REMOTE_MOUNTPOINT/provision.sh"
fi

# if it's the cluster master add the LXC remote so we can manage it.
if [[ $IS_MASTER == 1 ]]; then
	BCM_ENDPOINT_VM_IP=$(./get_endpoint_ip.sh --provider="$BCM_PROVIDER_NAME" --endpoint-name="$BCM_CLUSTER_ENDPOINT_NAME")
	./add_endpoint_lxd_remote.sh --cluster-name="$BCM_CLUSTER_NAME" --provider="$BCM_PROVIDER_NAME" --endpoint="$BCM_CLUSTER_ENDPOINT_NAME" --endpoint-ip="$BCM_ENDPOINT_VM_IP" --endpoint-lxd-secret="$BCM_LXD_SECRET"
fi
