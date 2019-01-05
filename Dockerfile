FROM alpine:3.7 as prep

LABEL maintainer="Tomohisa Kusano <siomiz@gmail.com>" \
      contributors="See CONTRIBUTORS file <https://github.com/siomiz/SoftEtherVPN/blob/master/CONTRIBUTORS>"

ENV BUILD_VERSION=5.01.9667 \
    SHA256_SUM=7b48cfa197e1958c2a86abd97832176eb06023bddbc10ae0e60548f142e7056d \
    CPU_FEATURES_VERSION=v0.2.0 \
    CPU_FEATURES_VERIFY=4AEE18F83AFDEB23

RUN wget https://github.com/SoftEtherVPN/SoftEtherVPN/archive/${BUILD_VERSION}.tar.gz \
    && echo "${SHA256_SUM}  ${BUILD_VERSION}.tar.gz" | sha256sum -c \
    && mkdir -p /usr/local/src \
    && tar -x -C /usr/local/src/ -f ${BUILD_VERSION}.tar.gz \
    && rm ${BUILD_VERSION}.tar.gz

# FIXME: can "git submodule update" (or "git clone") be properly secured?
RUN apk add git gnupg \
    && gpg --keyserver hkp://keys.gnupg.net --recv-keys ${CPU_FEATURES_VERIFY} \
    && git clone https://github.com/google/cpu_features.git /usr/local/src/SoftEtherVPN-${BUILD_VERSION}/src/Mayaqua/3rdparty/cpu_features \
    && cd /usr/local/src/SoftEtherVPN-${BUILD_VERSION}/src/Mayaqua/3rdparty/cpu_features \
    && git checkout ${CPU_FEATURES_VERSION} \
    && git verify-commit ${CPU_FEATURES_VERSION} \
    && cd -

FROM centos:7 as build

COPY --from=prep /usr/local/src /usr/local/src

RUN yum -y update \
    && yum -y groupinstall "Development Tools" \
    && yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && yum -y install ncurses-devel openssl-devel readline-devel cmake3

RUN cd /usr/local/src/SoftEtherVPN-* \
    && ln -s /usr/bin/cmake3 /usr/bin/cmake \
    && ./configure \
    && make -C tmp \
    && make install -C tmp \
    && touch /usr/local/libexec/softether/vpnserver/vpn_server.config \
    && zip -r9 /artifacts.zip \
       /usr/local/lib64/libcedar.so \
       /usr/local/lib64/libmayaqua.so \
       /usr/local/libexec/softether/* \
       /usr/local/bin/vpn*

FROM centos:7

COPY --from=build /artifacts.zip /

COPY copyables /

RUN yum -y update \
    && yum -y install unzip iptables sysvinit-tools \
    && rm -rf /var/log/* /var/cache/yum/* /var/lib/yum/* \
    && chmod +x /entrypoint.sh /gencert.sh \
    && unzip -o /artifacts.zip -d / \
    && rm /artifacts.zip \
    && rm -rf /opt \
    && ln -s /usr/vpnserver /opt \
    && find /usr/local/bin/vpn* -type f ! -name vpnserver \
       -exec sh -c 'ln -s {} /opt/$(basename {})' \;

WORKDIR /usr/vpnserver/

VOLUME ["/usr/vpnserver/server_log/"]

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 500/udp 4500/udp 1701/tcp 1194/udp 5555/tcp 443/tcp

CMD ["/usr/local/bin/vpnserver", "execsvc"]
