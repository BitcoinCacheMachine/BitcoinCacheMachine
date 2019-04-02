
# BCM Versioning

Various BCM versions are defined in ./env, which is available to all BCM scripts via the active signed git tag of `$BCM_GIT_DIR`. The format is as following:

```bash
# vLTS.SYSTEM.APP
BCM_VERSION="v0.0.0"
```

LTS:        Changes in major LTS REQUIRE a full-backup of user data to off-site storage, complete redeployment of your BCM infrastructure including base OS, and recovery of data. LTS updates use Disaster Recovery methodology (see below).
SYSTEM:     If a version changes a the SYSTEM level, all LXD System-level container and associated LXD resources (e.,g., profiles, volumes, networks) are created and old versions of resources are culled.
APP:        Changes here require a rebuilding and redeployment of any docker-based image (app-level containers).

The current GIT tag of $BCM_GIT_DIR defines the authoritative current version number.
