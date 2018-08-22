# DHCP / DNS / Routing

This section runs a special stack meant for base underlay network services. The `cachestack` LXD host has the eth4 interface with a static IP address of 192.168.99.1. This interface effectively becomes the new default gateway for hosts obtaining an IP address on the underlay. This IP address runs IP tables for IP routing. It also runs DHCP and DNS based on dnsmasq.