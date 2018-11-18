#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"
source ../host_template/defaults.sh
source ./defaults.sh

# lxc exec $BCM_GW_TEMPLATE_NAME -- apt-get install -y ufw tor
# lxc file push torrc $BCM_GW_TEMPLATE_NAME/etc/tor/torrc

# lxc exec $BCM_GW_TEMPLATE_NAME -- ufw allow in on localhost proto udp to any port 9053 # incoming DNS requests go over TOR
# lxc exec $BCM_GW_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 9050 # For TOR proxy (TODO)
# lxc exec $BCM_GW_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 3128 # HTTPS squid proxy
# #lxc exec $BCM_GW_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 3129 # HTTP redirect to HTTPS
# #lxc exec $BCM_GW_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 3130 # HTTPS
# #lxc exec $BCM_GW_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 80 # 80 for Docker Private REgistry
# lxc exec $BCM_GW_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 5000 # 5000 for docker registry pull through cache.
# lxc exec $BCM_GW_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 53 #DNS
# lxc exec $BCM_GW_TEMPLATE_NAME -- ufw allow in on eth1 proto udp to any port 53 #DNS
# lxc exec $BCM_GW_TEMPLATE_NAME -- ufw allow in on eth1 proto udp to any port 67 #DHCP
# #lxc exec BCM_GW_TEMPLATE_NAME -- ufw allow in on eth1 proto udp to any port 69 #TFTP
# lxc exec $BCM_GW_TEMPLATE_NAME -- ufw enable

# lxc stop $BCM_GW_TEMPLATE_NAME

# lxc config device remove $BCM_GW_TEMPLATE_NAME dockerdisk

# sleep 2

# lxc snapshot $BCM_GW_TEMPLATE_NAME bcm-gateway-snapshot


# # archived
# lxc file push ufw_before.rules bcm-gateway/etc/ufw/before.rules
# lxc file push ufw_sysctl.conf bcm-gateway/etc/ufw/sysctl.conf

# lxc exec bcm-gateway -- mkdir -p /etc/default
# lxc file push ufw.conf bcm-gateway/etc/default/ufw

# lxc exec bcm-gateway -- chown root:root /etc/ufw/before.rules
# lxc exec bcm-gateway -- chmod 0640 /etc/ufw/before.rules
# lxc exec bcm-gateway -- chown root:root /etc/ufw/sysctl.conf
# lxc exec bcm-gateway -- chmod 0644 /etc/ufw/sysctl.conf

# lxc exec bcm-gateway -- chown root:root /etc/default/ufw
# lxc exec bcm-gateway -- chmod 0644 /etc/default/ufw