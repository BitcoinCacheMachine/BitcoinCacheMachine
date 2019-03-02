# IPV4_ADDRESS="$(multipass list --format csv | grep $BCM_SSH_HOSTNAME | awk -F "\"*,\"*" '{print $3}')"
# echo "$IPV4_ADDRESS   $BCM_SSH_HOSTNAME" | sudo tee -a /etc/hosts