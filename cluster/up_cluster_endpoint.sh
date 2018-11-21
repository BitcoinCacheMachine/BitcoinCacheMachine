#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

IS_MASTER=0
BCM_CLUSTER_ENDPOINT_NAME=
BCM_PROVIDER_NAME=
BCM_CLUSTER_ENDPOINT_DIR=
BCM_ENDPOINT_VM_IP=

for i in "$@"
do
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

echo "up_cluster_endpoint.sh"
echo "IS_MASTER: $IS_MASTER"
echo "BCM_CLUSTER_ENDPOINT_NAME: $BCM_CLUSTER_ENDPOINT_NAME"
echo "BCM_PROVIDER_NAME: $BCM_PROVIDER_NAME"
echo "BCM_CLUSTER_ENDPOINT_DIR: $BCM_CLUSTER_ENDPOINT_DIR"

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
if [[ $BCM_PROVIDER_NAME != "baremetal" ]]; then
  if [[ -f $BCM_CLUSTER_ENDPOINT_DIR/lxd_preseed.yml ]]; then
    BCM_CLUSTER_MASTER_LXD_PRESEED=$(awk '{print "      " $0}' "$BCM_CLUSTER_ENDPOINT_DIR/lxd_preseed.yml" )
    export BCM_CLUSTER_MASTER_LXD_PRESEED
    
    BCM_LISTEN_INTERFACE=
    if [[ $BCM_PROVIDER_NAME = "multipass" ]]; then
      BCM_LISTEN_INTERFACE=ens3
    fi
    
    export BCM_LISTEN_INTERFACE=$BCM_LISTEN_INTERFACE
    envsubst < ./cloud_init_template.yml > $BCM_CLUSTER_ENDPOINT_DIR/cloud-init.yml
  fi
fi

if [[ $BCM_PROVIDER_NAME = 'baremetal' ]]; then
  bash -c "cat $BCM_CLUSTER_ENDPOINT_DIR/lxd_preseed.yml | sudo lxd init --preseed"
elif [[ $BCM_PROVIDER_NAME = "multipass" ]]; then
  ## launch the VM based with a static cloud-init.
  # we'll create lxd preseed files AFTER boot so we know the IP address.
  multipass launch \
    --disk "$BCM_ENDPOINT_DISK_SIZE" \
    --mem "$BCM_ENDPOINT_MEM_SIZE" \
    --cpus "$BCM_ENDPOINT_CPU_COUNT" \
    --name "$BCM_CLUSTER_ENDPOINT_NAME" \
    --cloud-init "$BCM_CLUSTER_ENDPOINT_DIR/cloud-init.yml" \
    cosmic

elif [[ $BCM_PROVIDER_NAME = "baremetal" ]]; then
  echo "todo; baremetal in up_cluster_endpoint.sh"
elif [[ $BCM_PROVIDER_NAME = "aws" ]]; then
  echo "todo; aws in up_cluster_endpoint.sh"
fi

# if it's the cluster master add the LXC remote so we can manage it.
if [[ $IS_MASTER = 1 ]]; then
  BCM_ENDPOINT_VM_IP=$(./get_endpoint_ip.sh --provider="$BCM_PROVIDER_NAME" --endpoint-name="$BCM_CLUSTER_ENDPOINT_NAME")
  ./add_endpoint_lxd_remote.sh --cluster-name="$BCM_CLUSTER_NAME" --endpoint="$BCM_CLUSTER_ENDPOINT_NAME" --endpoint-ip="$BCM_ENDPOINT_VM_IP" --endpoint-lxd-secret="$BCM_LXD_SECRET"
fi