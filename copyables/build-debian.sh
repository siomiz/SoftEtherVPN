#!/bin/bash

apt-get update

apt-get install -y --no-install-recommends \
    build-essential \
    libreadline7 \
    libreadline-dev \
    libssl1.1 \
    libssl-dev \
    libncurses5 \
    libncurses5-dev \
    zlib1g \
    zlib1g-dev \
    iptables \
    unzip \

cd /usr/local/src/SoftEtherVPN_Stable-*

./configure

make

make install

cd /

rm -rf /usr/local/src/SoftEtherVPN_Stable-*

apt-get purge -y \
    build-essential \
    libreadline-dev \
    libssl-dev \
    lib32ncurses5-dev \
    zlib1g-dev

apt-get -y autoremove

rm -rf /var/lib/apt/lists/*
