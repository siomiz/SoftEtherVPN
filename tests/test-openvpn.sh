#!/bin/bash
set -ex

openvpn --config test.ovpn --remote 172.30.0.3
