#!/bin/bash

# this script configures your local admin machine to install
# TIGHTVNC and expose it over an onion service.

mkdir -p /var/lib/tor/tightvnc/

HiddenServiceDir /var/lib/tor/tightvnc/
HiddenServicePort 5900 127.0.0.1:5900
HiddenServiceAuthorizeClient basic vncsupport
