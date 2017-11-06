#!/bin/bash
set -ex

ipsec auto --up meraki

echo "c meraki test test" > /var/run/xl2tpd/l2tp-control

echo "d meraki" > /var/run/xl2tpd/l2tp-control

ipsec down meraki

