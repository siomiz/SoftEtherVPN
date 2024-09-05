#!/bin/bash
set -e

VPNCMD=/usr/local/bin/vpncmd
VPNSERVER=/usr/local/bin/vpnserver

if [ "$*" == "gencert" ]; then

  /gencert.sh
  exit 0

fi

# check if iptables works (just warns)
set +e
iptables -L 2>/dev/null > /dev/null
if [[ $? -ne 0 ]]
then
  echo '# [!!] This image requires --cap-add NET_ADMIN'
  sleep 7
  # exit -1
fi
set -e

CONFIG=/usr/vpnserver/vpn_server.config

if [ ! -f $CONFIG ] || [ ! -s $CONFIG ]; then

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

printf '# '
printf '=%.0s' {1..24}
echo

vpncmd_server () {
  ${VPNCMD} localhost /SERVER /CSV /CMD "$@"
}

vpncmd_hub () {
  ${VPNCMD} localhost /SERVER /CSV /HUB:DEFAULT /CMD "$@"
}

${VPNSERVER} start 2>&1 > /dev/null

# while-loop to wait until server comes up
# switch cipher
while : ; do
  set +e
  vpncmd_server ServerCipherSet DHE-RSA-AES256-SHA 2>&1 > /dev/null
  [[ $? -eq 0 ]] && break
  set -e
  sleep 1
done

# About command to grab version number
# /usr/bin/vpncmd localhost /SERVER /CSV /CMD About | head -2 | tail -1 | sed 's/^/# /;'
vpncmd_server About | head -3 | tail -1 | sed 's/^/# /;'

# enable L2TP_IPsec
vpncmd_server IPsecEnable /L2TP:yes /L2TPRAW:yes /ETHERIP:no /PSK:${PSK} /DEFAULTHUB:DEFAULT

# enable SecureNAT
vpncmd_hub SecureNatEnable

# set MTU
: ${MTU:='1500'}
vpncmd_hub NatSet /MTU:$MTU /LOG:no /TCPTIMEOUT:3600 /UDPTIMEOUT:1800

# enable OpenVPN
# vpncmd_server OpenVpnEnable yes /PORTS:1194
# new command for 5 via https://github.com/SoftEtherVPN/SoftEtherVPN/discussions/1882
vpncmd_server ProtoOptionsSet OpenVPN /NAME:Enabled /VALUE:True
vpncmd_server PortsUDPSet 1194

# set server certificate & key
if [[ -f server.crt && -f server.key ]]; then
  vpncmd_server ServerCertSet /LOADCERT:server.crt /LOADKEY:server.key

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

  vpncmd_server ServerCertSet /LOADCERT:server.crt /LOADKEY:server.key
  rm server.crt server.key
  export KEY='**'
fi

vpncmd_server OpenVpnMakeConfig openvpn.zip 2>&1 > /dev/null

# extract .ovpn config
unzip -p openvpn.zip *_l3.ovpn > softether.ovpn
# delete "#" comments, \r, and empty lines
sed -i '/^#/d;s/\r//;/^$/d' softether.ovpn
# send to stdout
cat softether.ovpn

# disable extra logs
vpncmd_hub LogDisable packet
vpncmd_hub LogDisable security

# force user-mode SecureNAT
vpncmd_hub ExtOptionSet DisableIpRawModeSecureNAT /VALUE:true
vpncmd_hub ExtOptionSet DisableKernelModeSecureNAT /VALUE:true

# add user

adduser () {
    printf " $1"
    vpncmd_hub UserCreate $1 /GROUP:none /REALNAME:none /NOTE:none
    vpncmd_hub UserPasswordSet $1 /PASSWORD:$2
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

# handle VPNCMD_* commands right before setting admin passwords
if [[ $VPNCMD_SERVER ]]
then
  while IFS=";" read -ra CMD; do
    vpncmd_server $CMD
  done <<< "$VPNCMD_SERVER"
fi

if [[ $VPNCMD_HUB ]]
then
  while IFS=";" read -ra CMD; do
    vpncmd_hub $CMD
  done <<< "$VPNCMD_HUB"
fi

# set password for hub
: ${HPW:=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 16 | head -n 1)}
vpncmd_hub SetHubPassword ${HPW}

# set password for server
: ${SPW:=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 20 | head -n 1)}
vpncmd_server ServerPasswordSet ${SPW}

${VPNSERVER} stop 2>&1 > /dev/null

# while-loop to wait until server goes away
set +e
while [[ $(pidof vpnserver) ]] > /dev/null; do sleep 1; done
set -e

echo \# [initial setup OK]

else

echo \# [running with existing config]

fi

if [[ -d "/opt/scripts/" ]]; then
  while read _script; do
    echo >&2 ":: executing $_script..."
    bash -n "$_script" \
    && bash "$_script"
  done < <(find /opt/scripts/ -type f -iname "*.sh")
fi

exec "$@"
