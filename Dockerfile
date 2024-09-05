FROM alpine:3.20 AS prep

LABEL maintainer="Tomohisa Kusano <siomiz@gmail.com>" \
      contributors="See CONTRIBUTORS file <https://github.com/siomiz/SoftEtherVPN/blob/master/CONTRIBUTORS>"

ENV BUILD_VERSION=5.02.5185 \
    GIT_VERIFY_PUBKEY=B5690EEEBB952194

WORKDIR /usr/local/src/SoftEtherVPN

# RUN wget https://github.com/SoftEtherVPN/SoftEtherVPN/archive/refs/tags/${BUILD_VERSION}.tar.gz \
#     && echo "${SHA256_SUM}  ${BUILD_VERSION}.tar.gz" | sha256sum -c \
#     && mkdir -p /usr/local/src \
#     && tar -x -C /usr/local/src/ -f ${BUILD_VERSION}.tar.gz \
#     && rm ${BUILD_VERSION}.tar.gz

RUN apk add -U git gnupg \
    && git clone https://github.com/SoftEtherVPN/SoftEtherVPN.git --depth 1 --single-branch --branch=${BUILD_VERSION} . \
    && gpg --receive-keys ${GIT_VERIFY_PUBKEY} \
    && git verify-commit ${BUILD_VERSION} \
    && git submodule init \
    && git submodule update --recommend-shallow

FROM alpine:3.20 AS build

COPY --from=prep /usr/local/src /usr/local/src

ENV LANG=en_US.UTF-8 \
    USE_MUSL=YES

RUN apk add -U build-base cmake libsodium-dev ncurses-dev openssl-dev readline-dev zip zlib-dev \
    && cd /usr/local/src/SoftEtherVPN \
    && ./configure \
    && make -C build \
    && make -C build install \
    && zip -r9 /artifacts.zip \
       /usr/local/bin/vpn* /usr/local/libexec/softether/* \
       /usr/local/lib/libcedar.so /usr/local/lib/libmayaqua.so \
       /usr/lib/libsodium.so* \
       /usr/local/bin/list_cpu_features

FROM alpine:3.20

COPY --from=build /artifacts.zip /

COPY copyables /

ENV LANG=en_US.UTF-8

RUN apk add -U --no-cache bash iptables openssl-dev \
    && chmod +x /entrypoint.sh /gencert.sh \
    && unzip -o /artifacts.zip -d / \
    && rm /artifacts.zip \
    && rm -rf /opt \
    && ln -s /usr/vpnserver /opt \
    && find /usr/local/bin/vpn* -type f ! -name vpnserver \
       -exec sh -c 'ln -s {} /opt/$(basename {})' \;

WORKDIR /usr/vpnserver/

VOLUME ["/usr/vpnserver/server_log/", "/usr/vpnserver/packet_log/", "/usr/vpnserver/security_log/"]

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 500/udp 4500/udp 1701/tcp 1194/udp 5555/tcp 443/tcp

CMD ["/usr/local/bin/vpnserver", "execsvc"]
