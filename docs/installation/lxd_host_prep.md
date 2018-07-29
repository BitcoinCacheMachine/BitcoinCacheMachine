
#if BCM_CACHE_STACK_IP has a value set, configure the rest of the env vars
if [[ ! -z $BCM_CACHE_STACK ]]; then

  # configure the LXD daemon to obtain images from the BCM CACHE Stack
  if [[ -z $(lxc remote list | grep lxdcache) ]]; then
    echo "Adding lxd image server $BCM_CACHE_STACK:8443"
    lxc remote add lxdcache "$BCM_CACHE_STACK" --public --accept-certificate
    echo "Coping a cloud-based Ubuntu 18.04 image from the LXD daemon on ${BCM_CACHE_STACK_IP}:8443"
    lxc image copy lxdcache:bcm-bionic local: --alias bcm-bionic
  fi


  export BCM_REGISTRY_PROXY_REMOTEURL=http://${BCM_CACHE_STACK_IP}:5000
  export BCM_ELASTIC_REGISTRY_PROXY_REMOTEURL=http://${BCM_CACHE_STACK_IP}:5020

  # set HTTP and HTTPS proxy environment variables
  export HTTP_PROXY=${BCM_CACHE_STACK_IP}
  export HTTPS_PROXY=${BCM_CACHE_STACK_IP}

else
  if [[ $BCM_INSTALLATION != 'cachestack' ]]; then
    echo "BCM_CACHE_STACK not specified. LXD Image Cache not configured. Ubuntu 18.04 LXD will be downloaded from the Internet."
    
    echo "Clearing lxd proxy_http. HTTP requests made by LXD will be downloaded from the Internet."
    lxc config set core.proxy_http ""
    
    echo "Clearing lxd proxy_https. HTTPS requests made by LXD will be downloaded from the Internet."
    lxc config set core.proxy_https ""

    lxc config set core.proxy_ignore_hosts ""
  fi
fi
