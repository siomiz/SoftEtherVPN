#!/bin/bash
set -e

/opt/vpnserver start 2>&1 > /dev/null

sleep 3

# enable L2TP_IPsec
/opt/vpncmd localhost /SERVER /CSV /CMD IPsecEnable /L2TP:yes /L2TPRAW:no /ETHERIP:no /PSK:notasecret /DEFAULTHUB:DEFAULT

# enable SecureNAT
/opt/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD SecureNatEnable

# add user
UN=user$(cat /dev/urandom | tr -dc '0-9' | fold -w 4 | head -n 1)
PW=$(cat /dev/urandom | tr -dc '0-9' | fold -w 20 | head -n 1 | sed 's/.\{4\}/&./g;s/.$//;')
printf '=%.0s' {1..24}
echo
echo ${UN}
echo ${PW}
printf '=%.0s' {1..24}
echo

/opt/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD UserCreate ${UN} /GROUP:none /REALNAME:none /NOTE:none
/opt/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD UserPasswordSet ${UN} /PASSWORD:${PW}

# set password for hub
HPW=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 16 | head -n 1)
/opt/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD SetHubPassword ${HPW}

# set password for server
SPW=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 20 | head -n 1)
/opt/vpncmd localhost /SERVER /CSV /CMD ServerPasswordSet ${SPW}

/opt/vpnserver stop 2>&1 > /dev/null

exec "$@"
