#!/bin/bash


#https://github.com/koalaman/shellcheck/wiki/Recursiveness

# goal is to one day get the output of this command down to nothing.
find "$BCM_LOCAL_GIT_REPO_DIR" -type f -name "*.sh" -exec "shellcheck" "--format=gcc" {} \;