#!/bin/bash

cd "$(dirname "$0")"

bash -c "../stack_deploy_template.sh squid squid 3128"
