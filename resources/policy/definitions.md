

# Definitions

## System Data

System data are LXD-related resources such as containers, networks, profiles, and volume definitions. This data is NOT necessary to retain since it is artifacts of the BCM source code resository.

## User Data

User data is any data that is generated from app-level containers. Examples include the contents of bcm_btrfs volumes ending in '-docker'. User data is expected to be backed up using Local-HA and Lightning-enabled decentralized storage (TBD). User data consists of static file data contained in docker volumes and logging data collected by managed by the Kafka stack.

# Disaster Recovery Methodology

BCM is a distributed system and works to maintain local high availability of user data. In addition, BCM works to ensure that all data is fully backed up off-site to achieve disaster recovery. The goal is to implement a system that backs-up user-data to a decentralized storage service that accepts Bitcoin Lightning payments (future work).

When a Disaster Recovery occurs, a completely new BCM infrastructure is deployed from sctrach. After the new version is deployed and BEFORE user-services are started, data is recovered from the decentralized storage service. Once data is restored, app-level services are started. New keys GPG keys will be required since new infrastructure is being deployed.