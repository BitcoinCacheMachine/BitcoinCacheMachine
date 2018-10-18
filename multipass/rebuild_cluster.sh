#!/bin/bash

# destroy the cluster CLUS1
bash -c "./destroy_cluster.sh -c CLUS1"

sleep 5

bash -c "./up_multipass_cluster.sh -c CLUS1 -m 3"
