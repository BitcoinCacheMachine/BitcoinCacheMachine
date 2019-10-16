#!/bin/bash

#https://github.com/koalaman/shellcheck/wiki/Recursiveness

# goal is to one day get this command to emit (basically) nothing.
export SHELLCHECK_OPTS="-e SC1091"


find "$(dirname "$(which bcm)")/" -type f -name "*.sh" -exec "shellcheck" "--format=gcc" {} \;
