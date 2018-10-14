#!/bin/bash

#!/bin/bash

# brings up LXD cluster of 3 multipass vms.

export BCM_MULTIPASS_VM_NAME="bcm-02"
bash -c ./destroy_multipass.sh

export BCM_MULTIPASS_VM_NAME="bcm-01"
bash -c ./destroy_multipass.sh

