#!/bin/bash
set -ex

openvpn --config test.ovpn --auth-user-pass userpass --daemon --writepid openvpn.pid

ping -c 3 -W 10 -I tun0 1.1.1.1
