FROM centos:centos7

MAINTAINER Tomohisa Kusano <siomiz@gmail.com>

COPY build.sh /build.sh
RUN chmod +x /build.sh \
    && /build.sh \
    && rm /build.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /opt

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 500/udp 4500/udp 1701/tcp

CMD ["/opt/vpnserver", "execsvc"]
