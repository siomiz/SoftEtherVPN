#!/bin/bash
set -ex

apt-get update -y
apt-get install -y openvpn

# use the docker logs as .ovpn config file
# wait until OK is in output (apt-gets above most likely took enough time though)
docker logs --follow vpntest-openvpn | grep -qe "[initial setup OK]"
docker logs vpntest-openvpn > test.ovpn

