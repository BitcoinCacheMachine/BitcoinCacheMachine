#!/bin/bash

#https://github.com/koalaman/shellcheck/wiki/Recursiveness

# goal is to one day get this command to emit (basically) nothing.
find "$BCM_GIT_DIR" -type f -name "*.sh" -exec "shellcheck" "--format=gcc" {} \;
