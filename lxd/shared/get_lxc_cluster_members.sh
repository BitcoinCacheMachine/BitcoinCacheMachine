#!/bin/bash

echo $(lxc cluster list | grep $BCM_CLUSTER_NAME | cut -f1,2 -d'|' | awk '{print $2}')
