#!/bin/bash
set -ex

ipsec up softethervpn

echo "c softethervpn test test" > /var/run/xl2tpd/l2tp-control

echo "d softethervpn" > /var/run/xl2tpd/l2tp-control

ipsec down softethervpn

