#!/bin/bash
set -e

if [ "$*" == "gencert" ]; then

  /gencert.sh
  exit 0

fi

if [ ! -f /usr/vpnserver/vpn_server.config ]; then

: ${PSK:='notasecret'}

printf '# '
printf '=%.0s' {1..24}
echo

if [[ $USERS ]]
then
  echo '# <use the password specified at -e USERS>'
else
  : ${USERNAME:=user$(cat /dev/urandom | tr -dc '0-9' | fold -w 4 | head -n 1)}
  echo \# ${USERNAME}

  if [[ $PASSWORD ]]
  then
    echo '# <use the password specified at -e PASSWORD>'
  else
    PASSWORD=$(cat /dev/urandom | tr -dc '0-9' | fold -w 20 | head -n 1 | sed 's/.\{4\}/&./g;s/.$//;')
    echo \# ${PASSWORD}
  fi
fi

: ${MTU:='1500'}
echo "# SecureNat MTU set to $MTU"

printf '# '
printf '=%.0s' {1..24}
echo

/usr/bin/vpnserver start 2>&1 > /dev/null

# while-loop to wait until server comes up
# switch cipher
while : ; do
  set +e
  /usr/bin/vpncmd localhost /SERVER /CSV /CMD ServerCipherSet DHE-RSA-AES256-SHA 2>&1 > /dev/null
  [[ $? -eq 0 ]] && break
  set -e
  sleep 1
done

# About command to grab version number
/usr/bin/vpncmd localhost /SERVER /CSV /CMD About | head -2 | tail -1 | sed 's/^/# /;'

# enable L2TP_IPsec
/usr/bin/vpncmd localhost /SERVER /CSV /CMD IPsecEnable /L2TP:yes /L2TPRAW:yes /ETHERIP:no /PSK:${PSK} /DEFAULTHUB:DEFAULT

# enable SecureNAT
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD SecureNatEnable
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD NatSet /MTU:$MTU /LOG:no /TCPTIMEOUT:3600 /UDPTIMEOUT:1800
# enable OpenVPN
/usr/bin/vpncmd localhost /SERVER /CSV /CMD OpenVpnEnable yes /PORTS:1194

# set server certificate & key
if [[ -f server.crt && -f server.key ]]; then
  /usr/bin/vpncmd localhost /SERVER /CSV /CMD ServerCertSet /LOADCERT:server.crt /LOADKEY:server.key

elif [[ "*${CERT}*" != "**" && "*${KEY}*" != "**" ]]; then
  # server cert/key pair specified via -e
  CERT=$(echo ${CERT} | sed -r 's/\-{5}[^\-]+\-{5}//g;s/[^A-Za-z0-9\+\/\=]//g;')
  echo -----BEGIN CERTIFICATE----- > server.crt
  echo ${CERT} | fold -w 64 >> server.crt
  echo -----END CERTIFICATE----- >> server.crt

  KEY=$(echo ${KEY} | sed -r 's/\-{5}[^\-]+\-{5}//g;s/[^A-Za-z0-9\+\/\=]//g;')
  echo -----BEGIN PRIVATE KEY----- > server.key
  echo ${KEY} | fold -w 64 >> server.key
  echo -----END PRIVATE KEY----- >> server.key

  /usr/bin/vpncmd localhost /SERVER /CSV /CMD ServerCertSet /LOADCERT:server.crt /LOADKEY:server.key
  rm server.crt server.key
  export KEY='**'
fi

/usr/bin/vpncmd localhost /SERVER /CSV /CMD OpenVpnMakeConfig openvpn.zip 2>&1 > /dev/null

# extract .ovpn config
unzip -p openvpn.zip *_l3.ovpn > softether.ovpn
# delete "#" comments, \r, and empty lines
sed -i '/^#/d;s/\r//;/^$/d' softether.ovpn
# send to stdout
cat softether.ovpn

# disable extra logs
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD LogDisable packet
/usr/bin/vpncmd localhost /SERVER /CSV /HUB:DEFAULT /CMD LogDisable security

# add user

adduser () {
    printf " $1"
    /usr/bin/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD UserCreate $1 /GROUP:none /REALNAME:none /NOTE:none
    /usr/bin/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD UserPasswordSet $1 /PASSWORD:$2
}

printf '# Creating user(s):'

if [[ $USERS ]]
then
  while IFS=';' read -ra USER; do
    for i in "${USER[@]}"; do
      IFS=':' read username password <<< "$i"
      # echo "Creating user: ${username}"
      adduser $username $password
    done
  done <<< "$USERS"
else
  adduser $USERNAME $PASSWORD
fi

echo

export USERS='**'
export PASSWORD='**'

# set password for hub
: ${HPW:=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 16 | head -n 1)}
/usr/bin/vpncmd localhost /SERVER /HUB:DEFAULT /CSV /CMD SetHubPassword ${HPW}

# set password for server
: ${SPW:=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 20 | head -n 1)}
/usr/bin/vpncmd localhost /SERVER /CSV /CMD ServerPasswordSet ${SPW}

/usr/bin/vpnserver stop 2>&1 > /dev/null

# while-loop to wait until server goes away
set +e
while [[ $(pidof vpnserver)  ]] > /dev/null; do sleep 1; done
set -e

echo \# [initial setup OK]

fi

if [[ -d "/opt/scripts/" ]]; then
  while read _script; do
    echo >&2 ":: executing $_script..."
    bash -n "$_script" \
    && bash "$_script"
  done < <(find /opt/scripts/ -type f -iname "*.sh")
fi

exec "$@"
