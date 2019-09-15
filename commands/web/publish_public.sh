#!/bin/bash

# this script creates


mkdir -p $HOME/.aws

if [ ! -f $HOME/.aws/bcm ]; then
    aws ec2 create-key-pair --key-name bcm --query 'KeyMaterial' --output text > $HOME/.aws/bcm
fi

#chmod 0400 $HOME/.aws/bcm

aws ec2 run-instances \
--image-id ami-07d0cf3af28718ef8 \
--count 1 \
--instance-type t2.micro \
--key-name bcm 


#--security-group-ids sg-903004f8 \


#--subnet-id subnet-6e7f829e
