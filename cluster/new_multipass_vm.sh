#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VM_NAME=bcm-01
DISK_SIZE="50GB"
MEM_SIZE="2048"
CPU_COUNT=2


for i in "$@"; do
    case $i in
        --vmname=*)
            VM_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --disk-size=*)
            DISK_SIZE="${i#*=}"
            shift # past argument=value
        ;;
        --mem-size=*)
            MEM_SIZE="${i#*=}"
            shift # past argument=value
        ;;
        --cups=*)
            CPU_COUNT="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

multipass launch \
--disk "$DISK_SIZE" \
--mem "$MEM_SIZE" \
--cpus "$CPU_COUNT" \
--name "$VM_NAME" \
--cloud-init ./cloud_init_template.yml \
bionic
