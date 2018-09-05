


# #lxc exec bcm-gateway -- ifmetric eth0 25



# lxc exec bcm-gateway -- ufw allow in on eth1 proto tcp to any port 9050 #OUTBOUND TOR
# lxc exec bcm-gateway -- ufw allow in on eth1 proto tcp to any port 3128 #HTTP
# lxc exec bcm-gateway -- ufw allow in on eth1 proto tcp to any port 3129 #HTTP redirect to HTTPS
# lxc exec bcm-gateway -- ufw allow in on eth1 proto tcp to any port 3130 #HTTPS
# lxc exec bcm-gateway -- ufw allow in on eth1 proto tcp to any port 53 #DNS
# lxc exec bcm-gateway -- ufw allow in on eth1 proto udp to any port 53 #DNS
# lxc exec bcm-gateway -- ufw allow in on eth1 proto udp to any port 67 #DHCP
# lxc exec bcm-gateway -- ufw allow in on eth1 proto udp to any port 69 #TFTP
# lxc exec bcm-gateway -- ufw enable

