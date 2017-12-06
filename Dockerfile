FROM centos:centos7

LABEL maintainer="Tomohisa Kusano <siomiz@gmail.com>" \
      contributor="Ian Neubert <github.com/ianneub>" \
      contributor="Ky-Anh Huynh <github.com/icy>" \
      contributor="Max Kuchin <mkuchin@gmail.com>"

ENV BUILD_VERSION v4.22-9634-beta

COPY copyables /
RUN chmod +x /entrypoint.sh /gencert.sh

RUN bash /build.sh \
    && rm /build.sh

WORKDIR /opt

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 500/udp 4500/udp 1701/tcp 1194/udp 5555/tcp

CMD ["/usr/local/sbin/run"]
