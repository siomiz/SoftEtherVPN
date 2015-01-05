#!/bin/bash
set -e

: ${PSK:='notasecret'}
: ${USERNAME:=user$(cat /dev/urandom | tr -dc '0-9' | fold -w 4 | head -n 1)}

printf '=%.0s' {1..24}
echo
echo ${USERNAME}

if [[ $PASSWORD ]]
then
  echo '<use the password specified at -e PASSWORD>'
else
  PASSWORD=$(cat /dev/urandom | tr -dc '0-9' | fold -w 20 | head -n 1 | sed 's/.\{4\}/&./g;s/.$//;')
  echo ${PASSWORD}
fi  

printf '=%.0s' {1..24}
echo

/opt/vpnserver start 2>&1 > /dev/null

sleep 3

# switch cipher
/opt/vpncmd localhost /SERVER /CSV /CMD ServerCipherSet DHE-RSA-AES256-SHA

# enable L2TP_IPsec
/opt/vpncmd localhost /SERVER /CSV /CMD IPsecEnable /L2TP:yes /L2TPRAW:yes /ETHERIP:no /PSK:${PSK} /DEFAULTHUB:DEFAULT

# enable SecureNAT
/opt/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD SecureNatEnable

# add user
/opt/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD UserCreate ${USERNAME} /GROUP:none /REALNAME:none /NOTE:none
/opt/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD UserPasswordSet ${USERNAME} /PASSWORD:${PASSWORD}

export PASSWORD='**'

# set password for hub
HPW=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 16 | head -n 1)
/opt/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD SetHubPassword ${HPW}

# set password for server
SPW=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 20 | head -n 1)
/opt/vpncmd localhost /SERVER /CSV /CMD ServerPasswordSet ${SPW}

/opt/vpnserver stop 2>&1 > /dev/null

exec "$@"
