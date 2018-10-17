#!/bin/bash


output="$(lxc cluster list |  grep ONLINE | cut -f1,2 -d'|')"
FOO_NO_WHITESPACE="$(echo -e "${output}" | tr -d '[:space:]')"
