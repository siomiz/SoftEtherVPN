#!/bin/bash
set -ex

docker network create --subnet 172.18.0.0/16 test-network

docker run \
  -d \
  --cap-add NET_ADMIN \
  -e USERNAME=test \
  -e PASSWORD=test \
  --network test-network \
  --ip 172.18.0.3 \
  siomiz/softethervpn:travis-ci
