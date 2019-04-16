#!/bin/sh

set -ex

/sbin/tini -g -- node rtl
