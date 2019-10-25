#!/bin/sh
set -e

export EASYRSA_PKI="/usr/vpnserver/pki"
export EASYRSA_REQ_CN="siomiz/softethervpn CA"
export EASYRSA_BATCH="yes"

# download and verify easyrsa
gpg --keyserver keys.gnupg.net --recv-keys 390D0D0E >/dev/null 2>&1
curl -o /tmp/EasyRSA.tgz -sSL https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.6/EasyRSA-unix-v3.0.6.tgz
curl -o /tmp/EasyRSA.tgz.sig -sSL https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.6/EasyRSA-unix-v3.0.6.tgz.sig
gpg --verify /tmp/EasyRSA.tgz.sig >/dev/null 2>&1

# extract to ./easyrsa
tar zxvf /tmp/EasyRSA.tgz --strip-components=1 --wildcards */easyrsa "*/openssl-easyrsa.cnf" */x509-types >/dev/null

./easyrsa init-pki >/dev/null 2>&1

mv openssl-easyrsa.cnf pki

./easyrsa build-ca nopass >/dev/null 2>&1

./easyrsa build-server-full server nopass >/dev/null 2>&1

./easyrsa build-client-full client nopass >/dev/null 2>&1
