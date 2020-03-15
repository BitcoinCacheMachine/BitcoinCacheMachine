#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

VALUE="${2:-}"
if [ ! -z "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a web command."
    cat ./help.txt
    exit
fi

ENV_PATH=

for i in "$@"; do
    case $i in
        --env=*)
            ENV_PATH="${i#*=}"
            shift # past argument=value
        ;;
        *) ;;
    esac
done

# exit if the ENV_PATH was not set.
if [[ ! -f $ENV_PATH ]]; then
    echo "ERROR: ENV_PATH not set. Use '--env=/some/path/to/env/file'."
    exit 1
fi

EXTERNAL_PORT=
DOMAIN_NAME=
SITE_NAME=
SITE_PATH=

source "$ENV_PATH"
SITE_PATH=$(dirname $ENV_PATH)
if [[ -z $SITE_PATH ]]; then
    echo "ERROR: SITE_PATH not set."
    exit 1
fi


if [[ -z $SITE_NAME ]]; then
    echo "ERROR: SITE_NAME not set."
    exit 1
fi

HTML_DOCKERVOL="$SITE_NAME-site"
if ! docker volume list | grep -q "$HTML_DOCKERVOL"; then
    docker volume create "$HTML_DOCKERVOL"
fi

# now call the appropritate script.
if [[ $BCM_CLI_VERB == "build" ]]; then
    # this stores cached jekyll data that is pulled from the
    # internet the first time an image is created.
    BUILDCACHE_DOCKERVOL="$SITE_NAME-buildcache"
    if ! docker volume list | grep -q "$BUILDCACHE_DOCKERVOL"; then
        docker volume create "$BUILDCACHE_DOCKERVOL"
    fi
    
    BCM_DOCKER_BASE_TAG="jekyll/jekyll:3.8"
    if docker image list | grep -q "$BCM_DOCKER_BASE_TAG"; then
        docker image pull "$BCM_DOCKER_BASE_TAG"
    fi
    
    if [[ -f "$SITE_PATH/Dockerfile" ]]; then
        docker build --build-arg BCM_DOCKER_BASE_TAG="$BCM_DOCKER_BASE_TAG" -t "jekyll:$SITE_NAME" "$SITE_PATH/"
    fi
    
    echo "Building the image for '$SITE_PATH'."
    docker run --rm -it --volume="$BUILDCACHE_DOCKERVOL":/usr/local/bundle -v "$HTML_DOCKERVOL":/srv/jekyll/_site --volume="$SITE_PATH/jekyll_theme:/srv/jekyll" "jekyll:$SITE_NAME" jekyll build
fi

if [[ -z $DOMAIN_NAME ]]; then
    echo "ERROR: DOMAIN_NAME not set."
    exit 1
fi

if [[ -z $EXTERNAL_PORT ]]; then
    echo "ERROR: EXTERNAL_PORT not set."
    exit 1
fi

# Run serves the static _site directory using NGINX.
if [[ $BCM_CLI_VERB == "run" ]]; then
    
    bcm web build --env="$ENV_PATH"
    
    NGINX_IMAGE="nginx:latest"
    if docker image list | grep -q "$NGINX_IMAGE"; then
        docker image pull "$NGINX_IMAGE"
    fi
    
    if docker ps | grep -a "$SITE_NAME"; then
        docker kill "$SITE_NAME"
    fi
    
    docker system prune -f >> /dev/null
    docker run -d \
    --name="$SITE_NAME" \
    -p "$EXTERNAL_PORT:80" \
    -v "$HTML_DOCKERVOL:/usr/share/nginx/html:ro" \
    -e NGINX_HOST="$DOMAIN_NAME" \
    -e NGINX_PORT="$EXTERNAL_PORT" \
    "$NGINX_IMAGE"
    
    echo "Note! You can find a locally running copy of your site at $DOMAIN_NAME:$EXTERNAL_PORT"
fi

# in publish, we create a VM on AWS if it doesn't already exist and publish the website to it.
# future work, we can integrate DNS providers and wire that up too.
if [[ $BCM_CLI_VERB == "publish" ]]; then
    
fi
