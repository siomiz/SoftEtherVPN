#!/bin/bash
set -ex

apt-get update -y
apt-get install -y openvpn

# use the docker logs as .ovpn config file
# wait until OK is in output (apt-gets above most likely took enough time though)
docker logs --follow vpntest-openvpn | grep -qe "[initial setup OK]"
docker logs vpntest-openvpn > test.ovpn

# adjust `remote`
sed -i 's/^remote.*/remote 172.30.0.3 1194/' test.ovpn

# make credentials file for `--auth-user-pass`
echo test > userpass
echo test >> userpass
chmod 0400 userpass
