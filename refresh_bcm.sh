#!/bin/bash

source ./env

# first, let's commit and push our changes, so that the new VM will
# pull git from the published location. Note we do NOT mount BCM_GIT_DIR
# from the controller; it's always pulled from the GIT server endpoint
git add *
git commit --message="automated commit push."
git push

bash -c ./tests/destroy_vm.sh

bash -c ./tests/up_vm.sh
