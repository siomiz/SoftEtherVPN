#!/bin/bash

echo "clean_requirements_on_remove=1" >> /etc/yum.conf

yum -y update \
  && yum -y install unzip \
  && yum -y groupinstall "Development Tools" \
  && yum -y install readline-devel ncurses-devel openssl-devel iptables sysvinit-tools

# Build SoftEtherVPN

cd /usr/local/src/SoftEtherVPN_Stable-*

cp src/makefiles/linux_64bit.mak Makefile

make

make install

cd /

rm -rf /usr/local/src/SoftEtherVPN_Stable-*

# Clean-up
# Keep iptables (for vpnserver) & sysvinit-tools (for pidof)

yum -y remove readline-devel ncurses-devel openssl-devel \
  && yum -y groupremove "Development Tools" \
  && yum clean all
  
rm -rf /var/log/* /var/cache/yum/* /var/lib/yum/*

exit 0

