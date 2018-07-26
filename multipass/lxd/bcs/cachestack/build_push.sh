#!/bin/bash


docker build -t farscapian/lxdcache:latest ./lxdcache/
docker push farscapian/lxdcache:latest


docker build -t farscapian/ipfscache:latest ./ipfscache/
docker push farscapian/ipfscache:latest
