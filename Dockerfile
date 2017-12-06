FROM centos:centos7

MAINTAINER Tomohisa Kusano <siomiz@gmail.com>

ENV BUILD_VERSION=v4.22-9634-beta \
    DUMB_INIT_VERSION=v1.2.1

COPY copyables /
RUN chmod +x /entrypoint.sh /gencert.sh

RUN bash /build.sh \
    && rm /build.sh

WORKDIR /opt

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 500/udp 4500/udp 1701/tcp 1194/udp 5555/tcp

CMD ["/usr/local/bin/dumb-init", "--", "/opt/vpnserver", "execsvc"]
