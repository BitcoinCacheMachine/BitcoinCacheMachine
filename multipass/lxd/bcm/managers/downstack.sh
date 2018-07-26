#!/bin/bash

echo "Pushing kafka-tools and deploying stack."
lxc exec manager1 -- docker stack rm kafkatools
sleep 5 && lxc exec manager1 -- docker system prune -f && sleep 5 && lxc exec manager1 -- docker system prune -f --volumes & >> /dev/null
