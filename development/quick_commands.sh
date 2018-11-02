#!/bin/bash


export BCM_DEBUG=1

# create a multipass cluster
bcm cluster create -c=dev -t=multipass -l=3 -x=net

bcm cluster destroy -c=dev


bcm init -n=test -u=ubuntu -c=domain.com

# create a 3 node multipass cluster locally.
bcm cluster create -c=home -t=multipass -l=3 -x=net


