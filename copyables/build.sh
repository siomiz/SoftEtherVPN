#!/bin/bash

echo "clean_requirements_on_remove=1" >> /etc/yum.conf

yum -y update \
  && yum -y install unzip \
  && yum -y groupinstall "Development Tools" \
  && yum -y install readline-devel ncurses-devel openssl-devel iptables

git clone --depth 1 https://github.com/SoftEtherVPN/SoftEtherVPN.git /usr/local/src/vpnserver

cd /usr/local/src/vpnserver

cp src/makefiles/linux_64bit.mak Makefile
make

cp bin/vpnserver/vpnserver /opt/vpnserver
cp bin/vpnserver/hamcore.se2 /opt/hamcore.se2
cp bin/vpncmd/vpncmd /opt/vpncmd

rm -rf /usr/local/src/vpnserver

gcc -o /usr/local/sbin/run /usr/local/src/run.c

rm /usr/local/src/run.c

yum -y remove readline-devel ncurses-devel openssl-devel \
  && yum -y groupremove "Development Tools" \
  && yum clean all
  
rm -rf /var/log/* /var/cache/yum/* /var/lib/yum/*

exit 0
