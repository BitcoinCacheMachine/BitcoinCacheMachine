#!/bin/bash

# destroy the cluster CLUS1
bash -c "./destroy_cluster.sh -c CLUS1"

sleep 5

bash -c "./up_lxd_cluster.sh -c CLUS1 -m 3"



# bash -c "./destroy_cluster.sh CLUS2"
# bash -c "./up_lxd_cluster.sh CLUS2 2"



# bash -c "./destroy_cluster.sh CLUS3"
# bash -c "./up_lxd_cluster.sh CLUS3"
