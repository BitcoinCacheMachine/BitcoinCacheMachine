#!/bin/bash

source ./env

bash -c ./tests/destroy_vm.sh

bash -c ./tests/up_vm.sh
