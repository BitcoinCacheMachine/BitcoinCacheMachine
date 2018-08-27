# `gateway`

The `gateway` LXC container is intended to be deployed on computer that has at least two (2) physical network interfaces each connected to a distinct L2 broadcast domain. These interfaces are the `untrusted outside` and `trusted inside` interfaces and MUST exist as separate physical L2 broadcast domains. 

For the `untrusted outside` interface, macvlan is used to obtain an IP address and default gateway from the upstream DHCP server such that might be running on your DSL or cable modem or the Linksys or Netgear router providing DHCP on your internal home or office network. Since `gateway` uses macvlan on the `untrusted outside` interface, it can be used as the LXD endpoint, though would exist on a separate IP address. The outside interface obtains IP and default gateway information from a DHCP server upstream, such as a DSL or cable modem or your existing network. 

DHCP and DNS services are hosted via docker container listening on the `trusted inside` interface. This interface is physically attached to the `gateway` LXC container network interface, so `gateway` has exclusive control of the physical network interface. `gateway` can be configured to forward traffic originating on the `trusted inside` interface out the untrusted interface. The DNS server exposed on the `inside interface` is configured to use TOR for outbound external queries and cache known entries for local LAN clients.

DHCP clients requesting an IP information SHOULD provide a hostname which is auto-pushed into the DNS. A properly working `gateway` makes BCM deployments far easier and consistent because we know addressing and DNS are correctly configured!

Both the `untrusted outside` and `trusted inside` interfaces MUST be explicitly set by the administrator (see ./resources/defaults/gateway.env).