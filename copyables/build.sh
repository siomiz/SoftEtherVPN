#!/bin/bash

echo "clean_requirements_on_remove=1" >> /etc/yum.conf

yum -y update \
  && yum -y install unzip \
  && yum -y groupinstall "Development Tools" \
  && yum -y install readline-devel ncurses-devel openssl-devel iptables glibc-static

# Build SoftEtherVPN

git clone https://github.com/SoftEtherVPN/SoftEtherVPN_Stable.git /usr/local/src/vpnserver

cd /usr/local/src/vpnserver

git checkout ${BUILD_VERSION}

cp src/makefiles/linux_64bit.mak Makefile

make

cp bin/vpnserver/vpnserver /opt/vpnserver
cp bin/vpnserver/hamcore.se2 /opt/hamcore.se2
cp bin/vpncmd/vpncmd /opt/vpncmd

cd /

rm -rf /usr/local/src/vpnserver

# Build dumb-init

git clone https://github.com/Yelp/dumb-init.git /usr/local/src/dumb-init

cd /usr/local/src/dumb-init

git checkout ${DUMB_INIT_VERSION}

make

cp dumb-init /usr/local/bin/dumb-init

cd /

rm -rf /usr/local/src/dumb-init

# Clean-up

yum -y remove readline-devel ncurses-devel openssl-devel glibc-static \
  && yum -y groupremove "Development Tools" \
  && yum clean all
  
rm -rf /var/log/* /var/cache/yum/* /var/lib/yum/*

exit 0
