
# BCMNET

This folder hosts all applications that need to connect to the underlay network. In general, lxc hosts that have connectivity to the bcmnet network can access the following services hosted on lxc host `gateway` located at 192.168.4.1:

* Docker Registry Mirror accessible via 'bcmnet:5000' via TLS 1.3 with certificate-based client-server authentication.
* Docker Private Registry accessible via 'bcmnet:443' via TLS 1.3 with certificate-based client-server authentication.




