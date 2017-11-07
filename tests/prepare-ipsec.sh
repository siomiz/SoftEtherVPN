#!/bin/bash
set -ex

# based heavily on https://gist.github.com/psanford/42c550a1a6ad3cb70b13e4aaa94ddb1c

apt-get -qq update
apt-get install -y strongswan xl2tpd

cat > /etc/ipsec.conf <<EOF
config setup

conn %default
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1
    keyexchange=ikev1
    authby=secret
    ike=aes128-sha1-modp1024,3des-sha1-modp1024!
    esp=aes128-sha1-modp1024,3des-sha1-modp1024!

conn softethervpn
    keyexchange=ikev1
    left=%defaultroute
    auto=add
    authby=secret
    type=transport
    leftprotoport=17/1701
    rightprotoport=17/1701
    right=172.18.0.3
EOF

cat > /etc/ipsec.secrets <<EOF
: PSK "notasecret"
EOF

cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[lac softethervpn]
lns = 172.18.0.3
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF

cat > /etc/ppp/options.l2tpd.client <<EOF
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-mschap-v2
noccp
noauth
idle 1800
mtu 1410
mru 1410
defaultroute
usepeerdns
debug
lock
connect-delay 5000
EOF

mkdir -p /var/run/xl2tpd
touch /var/run/xl2tpd/l2tp-control

service strongswan restart
service xl2tpd restart

