# `gateway`

The `gateway` LXC container is intended to be deployed on computer that has at least two (2) physical network interfaces each connected to a distinct L2 broadcast domain. These interfaces are the `untrusted outside` and `trusted inside` interfaces and MUST exist as separate physical L2 broadcast domains. 

For the `untrusted outside` interface, macvlan is used to obtain an IP address and default gateway from the upstream DHCP server such that might be running on your DSL or cable modem or the Linksys or Netgear router providing DHCP on your internal home or office network. Since `gateway` uses macvlan on the `untrusted outside` interface, it can be used as the LXD endpoint, though would exist on a separate IP address. The outside interface obtains IP and default gateway information from a DHCP server upstream, such as a DSL or cable modem or your existing network. 

It's important to understand that the network `bcmnet` can be configured to attach to a physical LAN segment. This is required when you want to run your home or office network on more than one computer which is required if you require any kind of scale or if you need to run a component on specialized hardware (e.g., Bitcoin miner or IoT sensors).

To configure `gateway` to provide network services to a physical LAN segment (e.g., switch on a home/office network) ensure $BCM_GATEWAY_ATTACH_TO_UNDERLAY="true". The the $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE must also be specified. $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE is the physical network interface of the computer hosting the `gateway` LXC container. Type `lxc network list` to show network interfaces known to LXD. LXC container `bcm-gateway` physically attached to the BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE, so `bcm-gateway` has exclusive control of the physical network interface.

## Required Services provided by `bcm-gateway`

## DHCP 

DHCP clients requesting an IP information SHOULD provide a hostname which is auto-pushed into the DNS.

## DNS 

Both the `untrusted outside` and `trusted inside` interfaces MUST be explicitly set by the administrator (see ./resources/defaults/gateway.env).

## Docker Registry Mirror Image Cache

The registry mirror hosted on `gateway` is configured to use [certificate-based client-server authentication](https://docs.docker.com/engine/security/certificates/). Docker daemons having access to bcmnet use this mirror as an image-cache-of-last-resort. TODO is to implement TOR for outbound communication by docker registry process if possible. Note that general strategy, if possible, is to rely on privately built images, which get stored in the Private Registry (see below).

## Docker Private Registry

The Private Registry hosts all custom-built images. BCM structures docker image layers to minimze disk usage. Downstream docker daemons on `bcmnet` may push images to the private registry. The general strategy for creating custom docker images is to create an ephemeral build lxc container. These temporary `builder` containers pull base images from the Registry Mirror then performs the build process using `docker build`. Scripts then push the tagged image to the private registry located at `bcmnet:443`. Communication is secured using TLS 1.3 and uses certificate-based client-server authentication.

## Squid HTTPS proxy

