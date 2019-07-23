# Cachestack

When developing BCM, it may be useful and advantagous to deploy a Cachestack locally on your network. This allows you to download LXD images and Docker images from a local cache rather than having to download the images from images.lxd.com and dockerhub continually.

LXC image distribution and Docker image distribution and caching are extremely important cache-level services provided by BCM.  The Cachestack also hosts an IPFS daemon that services local clients on the network. The IPFS daemon portion should be configured to fetch an arbitrary number of objects (default and requested) and serve files via an IPFS HTTP endpoint.

When you run `bcm stack start cachestack`, a Docker registry mirror is deployed that mirrors Dockerhub. It exposes its services on port 5000 at the BCM MACVLAN IP address (`bcm get-ip`). Anyone developing or experimenting on BCM is advised to deploy a cachestack for better performance. Other caches will be added over time.
