#!/bin/bash

cd "$(dirname "$0")"

bash -c "../stack_deploy_template.sh registry_mirror regmirror 5000"
