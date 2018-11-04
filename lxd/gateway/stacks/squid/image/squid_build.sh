#!/bin/bash

# set squid version
source squid.ver

# get squid from debian experimental
wget http://http.debian.net/debian/pool/main/s/squid/squid_${SQUID_PKG}.dsc
wget http://http.debian.net/debian/pool/main/s/squid/squid_${SQUID_VER}.orig.tar.gz
wget http://http.debian.net/debian/pool/main/s/squid/squid_${SQUID_PKG}.debian.tar.xz

# unpack the source package
dpkg-source -x squid_${SQUID_PKG}.dsc

# modify configure options in debian/rules, add --enable-ssl --enable-ssl-crtd
patch squid-${SQUID_VER}/debian/rules < ./rules.patch

# build the package
cd squid-${SQUID_VER} && dpkg-buildpackage -rfakeroot -b
