#!/bin/bash

source ../env

bash -c ./destroy_vm.sh

bash -c ./up_vm.sh
