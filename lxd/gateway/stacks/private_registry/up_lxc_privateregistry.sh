#!/bin/bash

cd "$(dirname "$0")"

bash -c "../stack_deploy_template.sh private_registry privreg 443"