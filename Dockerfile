FROM alpine:3.14 as prep

LABEL maintainer="Tomohisa Kusano <siomiz@gmail.com>" \
      contributors="See CONTRIBUTORS file <https://github.com/siomiz/SoftEtherVPN/blob/master/CONTRIBUTORS>"

ENV BUILD_VERSION=4.38-9760-rtm \
    SHA256_SUM=7701dfb76b888d4adde19d9a39d0919681f6c091f3eb5295ec8caf0439eb3a1a

RUN wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/archive/v${BUILD_VERSION}.tar.gz \
    && echo "${SHA256_SUM}  v${BUILD_VERSION}.tar.gz" | sha256sum -c \
    && mkdir -p /usr/local/src \
    && tar -x -C /usr/local/src/ -f v${BUILD_VERSION}.tar.gz \
    && rm v${BUILD_VERSION}.tar.gz

FROM centos:8 as build

COPY --from=prep /usr/local/src /usr/local/src

RUN yum -y update \
    && yum -y groupinstall "Development Tools" \
    && yum -y install ncurses-devel openssl-devel readline-devel \
    && cd /usr/local/src/SoftEtherVPN_Stable-* \
    && ./configure \
    && make \
    && make install \
    && touch /usr/vpnserver/vpn_server.config \
    && zip -r9 /artifacts.zip /usr/vpn* /usr/bin/vpn*

FROM centos:8

COPY --from=build /artifacts.zip /

COPY copyables /

RUN yum -y update \
    && yum -y install unzip iptables \
    && rm -rf /var/log/* /var/cache/yum/* /var/lib/yum/* \
    && chmod +x /entrypoint.sh /gencert.sh \
    && unzip -o /artifacts.zip -d / \
    && rm /artifacts.zip \
    && rm -rf /opt \
    && ln -s /usr/vpnserver /opt \
    && find /usr/bin/vpn* -type f ! -name vpnserver \
       -exec sh -c 'ln -s {} /opt/$(basename {})' \;

WORKDIR /usr/vpnserver/

VOLUME ["/usr/vpnserver/server_log/", "/usr/vpnserver/packet_log/", "/usr/vpnserver/security_log/"]

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 500/udp 4500/udp 1701/tcp 1194/udp 5555/tcp 443/tcp

CMD ["/usr/bin/vpnserver", "execsvc"]
