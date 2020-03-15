# Major todo's for BCM

1. Ensure ALL management is SSH based for remote machines, either via local network/direct SSH, or via TOR hidden service. Similarly, all LXD operation will be local on the target device and use the local unix socket. That is, if deploying locally, the local LXD unix socket will be used. If SSHed into a remote machine (ssh or SSHoTor), the local unix socket on the remote machine will be used. This results in better performance and simplifies the management plane.

9. Back $BCM_RUNTIME_DIR as a mounted loop device with a LUKS partition, the password of which is stored in the $HOME/.password-store protected by the GPG certificate in $GNUPGHOME

2. Wire up Kafka logging for the LXD system containers. The Kafka stack is in place, but downstream LXD system containers (docker engines) are not configured to log to the kafka stack. A mechanism (logging_facility) will be implemented that switches the current logging between LXD (for development) and the kafka stack.

3. Ensure switching between mainnet, testnet, regtest, segnet, etc, are completed. Ensure existing images are pulled from the docker registry to speed up deployment.

4. Ensure all Bitcoin-related services (RPC, p2p, etc.) are exposed over the app-level TOR hidden service.

5. Ensure all services exist on dedicated docker overlay networks.

6. Start tagging BCM git repo for versioning purposes. All tags MUST be digitally signed.

7. Implement esplora stack for block exploration.

8. Implement JoinMarket as a stack.

