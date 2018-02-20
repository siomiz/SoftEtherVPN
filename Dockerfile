FROM debian:9-slim

LABEL maintainer="Tomohisa Kusano <siomiz@gmail.com>" \
      contributors="Ian Neubert <github.com/ianneub>; Ky-Anh Huynh <github.com/icy>; Max Kuchin <mkuchin@gmail.com>"

ENV BUILD_VERSION=4.25-9656-rtm

#install wget
RUN apt-get update \
    && apt-get install -y wget \
    && rm -rf /var/lib/apt/lists/*

#Get, extract and build softether
RUN wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/archive/v${BUILD_VERSION}.tar.gz && tar xf v${BUILD_VERSION}.tar.gz && rm v${BUILD_VERSION}.tar.gz \
    && apt-get update \
    && apt-get install -y --no-install-recommends build-essential libreadline7 libreadline-dev libssl1.1 libssl-dev libncurses5 libncurses5-dev zlib1g zlib1g-dev iptables unzip \
    && cd SoftEtherVPN_Stable-${BUILD_VERSION} \ && ./configure && make && make install && rm -rf /SoftEtherVPN_Stable-${BUILD_VERSION} \ && cd / \
    && apt-get purge -y build-essential libreadline-dev libssl-dev lib32ncurses5-dev zlib1g-dev && apt-get -y autoremove && apt-get -y clean && rm -rf /var/lib/apt/lists/*

COPY copyables /
RUN chmod +x /entrypoint.sh /gencert.sh

WORKDIR /usr/vpnserver/

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 500/udp 4500/udp 1701/tcp 1194/udp 5555/tcp

CMD ["/usr/bin/vpnserver", "execsvc"]
