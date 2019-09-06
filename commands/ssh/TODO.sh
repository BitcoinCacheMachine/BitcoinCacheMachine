# this script grabs the onion site and adds it to your local /etc/tor/torrc

# # now we wait for the service to start, then we grab the new onion site and token
# # then we add it to our config using bcm ssh add-onion
# DOCKER_CONTAINER_ID=$(lxc exec "$BCM_UNDERLAY_HOST_NAME" -- docker ps | grep toronion | awk '{print $1}')
# if [[ ! -z $DOCKER_CONTAINER_ID ]]; then
#     ONION_CREDENTIALS="$(lxc exec "$BCM_UNDERLAY_HOST_NAME" -- docker exec -t "$DOCKER_CONTAINER_ID" cat /var/lib/tor/bcmonion/hostname)"

#     if [[ ! -z $ONION_CREDENTIALS ]]; then
#         ONION_URL="$(echo "$ONION_CREDENTIALS" | awk '{print $1;}')"
#         ONION_TOKEN="$(echo "$ONION_CREDENTIALS" | awk '{print $2;}')"
#         bcm ssh add-onion --onion="$ONION_URL" --token="$ONION_TOKEN" --title="$(lxc remote get-default)"
#     fi
# else
#     echo "WARNING: Docker container not found for 'toronion'. You may need to run 'bcm stack start toronion'."
# fi
