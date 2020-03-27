#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"


source ./env

# first, let's build it so we're
bash -c ./build_site.sh

if docker image list | grep -q "$NGINX_IMAGE"; then
    docker image pull "$NGINX_IMAGE"
fi

if docker ps | grep -a "$SITE_NAME"; then
    docker kill "$SITE_NAME"
fi

docker system prune -f >> /dev/null
docker run -d --name="$SITE_NAME" \
-p "$SERVICE_ENDPOINT:80" \
-v "$SITE_PATH/_site:/usr/share/nginx/html:ro" \
-e NGINX_HOST="$DOMAIN_NAME" \
-e NGINX_PORT="$EXTERNAL_PORT" \
"$NGINX_IMAGE"

xdg-open "http://$SERVICE_ENDPOINT"
