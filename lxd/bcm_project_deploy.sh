#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"

# the cluster we're deploying the project to
BCM_CLUSTER_NAME=
BCM_PROJECT_NAME=
export BCM_LXD_OPS=$BCM_LOCAL_GIT_REPO_DIR/lxd/shared

for i in "$@"
do
case $i in
    --cluster-name=*)
    BCM_CLUSTER_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --project-name=*)
    BCM_PROJECT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --mgmt-type=*)
    BCM_MGMT_TYPE="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

# let's make sure the cluster exists.
if [[ -z $(bcm cluster list | grep "$BCM_CLUSTER_NAME") ]]; then
  echo "Cluster '$BCM_CLUSTER_NAME' does not exist. BCM Project '$BCM_PROJECT_NAME' will not be deployed."
  exit
fi

# let's make sure the project exists.
if [[ -z $(bcm project list | grep "$BCM_PROJECT_NAME") ]]; then
  echo "Project '$BCM_PROJECT_NAME' does not exist. Can't deploy."
  exit
fi

if [[ -z $(lxc project list | grep bcm) ]]; then
    lxc project create bcm -c features.images=false -c features.profiles=false
    mkdir -p $BCM_BCM_CLUSTER_DIR
    lxc project switch bcm
    #-c features.images=false -c features.profiles=false
fi

bash -c ./host_template/up_lxc_host_template.sh

# # If the admin hasn't specified an external LXD image server, then
# # we can only assume that we need to build a base image from scratch. 
# # it's best to centralize your image creation, but good for standalone deployments.
# if [[ ! -z $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE ]]; then
#   if [[ $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE = "none" ]]; then
#     # then we're going to arrive at 'bcm-template' by creating it ourselves'
    
#   else
#     # this is the logic that is taken when the administrator has specified a
#     # custom LXD image server which is typical of home and offince network deployments
#     if [[ $(lxc remote list | grep $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE) ]]; then
#       echo "Attempting to download the LXC image named 'bcm-template' from the LXD remote $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE to LXD remote $(lxc remote get-default):bcm-template"
#     else
#       echo "Error! LXD remote $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE not found."
#     fi
#   fi
# else
#   echo "BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE not set. Exiting. Consider running 'bcm' to load environment variables for the current LXD remote '$(lxc remote get-default)'"
#   exit
# fi

if [[ $BCM_ADMIN_GATEWAY_INSTALL = "true" ]]; then
  echo "Deploying 'bcm-gateway'."
  bash -c ./gateway/up_lxc_gateway.sh
fi

# if [[ $BCM_ADMIN_BCMNETTEMPLATE_CREATE = "true" ]]; then
#     echo "Creating lxc container '$BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME' and associated snapshot 'bcmnet_template'."
#     bash -c ./bcmnet/up_lxc_bcmnet.sh
# fi


# echo "Deploying app_hosts"
# bash -c ./app_hosts/up_lxc_apphosts.sh







# if [[ $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE = "none" ]]; then
#   # in this case, we deploy cachestack.
#   echo "Deploying local cachestack for BCM instance."
#   bash -c ./cachestack/up_lxd_cachestack.sh
# else
#   # in this assume the cachestack is defined in $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE
#   echo "Assuming external LXD endpoint '$BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE' is hosting a cachestack."
#   echo "Copying a prepared LXD system host image from $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE"
#   lxc image copy $BCM_LXD_EXTERNAL_BCM_TEMPLATE_REMOTE:bctemplate $(lxc remote get-default): --auto-update --copy-aliases
# fi
