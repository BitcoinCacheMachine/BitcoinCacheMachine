## Architecture

BCM is built entirely on Ubuntu 18.04 Bionic Beaver. BCM can run inside a VM or on bare-metal (preferred).  LXD/LXC system containers are used to provision system-level containers (analogous to a VM in the cloud). Docker daemon runs in each LXD system container and is responsible for running application-specific containers.

TCP 9050 (TOR) outbound is required for BCM to function. This is required since BCM exposes some of the services on the TOR overlay network facilitating client connections (e.g., a wallet app on your phone, or maybe a block explorer). This allows you to host your own infrastructure while maintaining a very cloud-like feel, all without having to fiddle with your external firewall.

BCM begins by deploying full Bitcoin infrastructure to the environment via LXD system containers running Docker daemon. A Bitcoin full node running Bitcoin Core 16.0 is deployed along with Lightning Network Daemon (lnd) (other implementations planned). BCM includes Kafka infrastructure for distributed messaging and stream processing. All logs are sent to Kafka which is the system of record for user data. Event processing if facilitated by Kafka Streams.

## Why use Docker Swarm and LXD?

LXD is used primarily to facilitate multi-tenancy across shared hardware for service provider use cases. Although this is useful for the enterprise providing shared infrastructure, it compromises individual sovereignty (necessarily)! The fact is, if you rely on someone else to run a part of your finances (including the financial system!), you cede your financial sovereignty! Why? Because you're stupidly relying on a "trusted" third-party to validate all transactions (including money supply)! In the 21st centruty, to be secure in your finances means to ALSO to independently validate the underlying financial system upon which you are recording your all your business transactions!  Bitcoin is the only public blockchain that is worthy of the property of "secure"!