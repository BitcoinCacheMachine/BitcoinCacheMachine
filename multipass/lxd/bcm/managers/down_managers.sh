#!/bin/bash

for MANAGER in manager1 manager2 manager3
do
    lxc delete --force $MANAGER
    lxc storage delete $MANAGER-dockervol
done

lxc network delete managernet >/dev/null

for MANAGER in manager1 manager2 manager3
do
    lxc profile delete $MANAGER
done

lxc delete --force manager-template > /dev/null
