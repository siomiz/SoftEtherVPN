FROM debian:9-slim

LABEL maintainer="Tomohisa Kusano <siomiz@gmail.com>" \
      contributors="Ian Neubert <github.com/ianneub>; Ky-Anh Huynh <github.com/icy>; Max Kuchin <mkuchin@gmail.com>; maltalex <github.com/maltalex>"

ENV BUILD_VERSION=4.25-9656-rtm \
    SHA256_SUM=c5a1791d69dc6d1c53fb574a3ce709707338520be797acbeac0a631c96c68330

#install wget
RUN apt-get update \
    && apt-get install -y wget \
    && rm -rf /var/lib/apt/lists/*

#Get, extract and build softether
RUN wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/archive/v${BUILD_VERSION}.tar.gz \
    && echo "${SHA256_SUM} v${BUILD_VERSION}.tar.gz" | sha256sum -c --strict --quiet \
    && tar xf v${BUILD_VERSION}.tar.gz && rm v${BUILD_VERSION}.tar.gz \
    && apt-get update && apt-get install -y --no-install-recommends \ 
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
    && cd SoftEtherVPN_Stable-${BUILD_VERSION} && ./configure && make && make install \
    && cd / && rm -rf /SoftEtherVPN_Stable-${BUILD_VERSION} \
    && apt-get purge -y \ 
        build-essential \
        libreadline-dev \ 
        libssl-dev \ 
        lib32ncurses5-dev \
        zlib1g-dev \
    && apt-get -y autoremove && rm -rf /var/lib/apt/lists/*

COPY copyables /

RUN chmod +x /entrypoint.sh /gencert.sh \
    && rm -rf /opt && ln -s /usr/vpnserver /opt \
    && find /usr/bin/vpn* -type f ! -name vpnserver \
       -exec bash -c 'ln -s {} /opt/$(basename {})' \;

WORKDIR /usr/vpnserver/

VOLUME ["/usr/vpnserver/server_log/"]

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 500/udp 4500/udp 1701/tcp 1194/udp 5555/tcp

CMD ["/usr/bin/vpnserver", "execsvc"]
