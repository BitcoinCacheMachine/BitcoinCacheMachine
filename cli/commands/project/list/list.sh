#!/bin/bash

set -eu

if [[ ! -d ~/.bcm/projects ]]; then
    mkdir -p ~/.bcm/projects
fi

if [[ $(ls -l ~/.bcm/projects | grep -c ^d) = "0" ]]; then
    exit
else
    cd ~/.bcm/projects/
    for project in `ls -d */ | sed 's/.$//'`; do
        if [[ ! -z $project ]]; then
            echo "$project"
        fi
    done
    cd - >> /dev/null
fi