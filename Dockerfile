FROM centos:centos7

MAINTAINER Tomohisa Kusano <siomiz@gmail.com>

RUN yum -y update \
	&& yum -y groupinstall "Development Tools" \
	&& yum -y install readline-devel ncurses-devel openssl-devel

RUN git clone https://github.com/SoftEtherVPN/SoftEtherVPN.git /usr/local/src/vpnserver

WORKDIR /usr/local/src/vpnserver

RUN cp src/makefiles/linux_64bit.mak Makefile
RUN make

RUN cp bin/vpnserver/vpnserver /opt/vpnserver
RUN cp bin/vpnserver/hamcore.se2 /opt/hamcore.se2
RUN cp bin/vpncmd/vpncmd /opt/vpncmd

WORKDIR /opt
RUN rm -rf /usr/local/src/vpnserver

RUN yum -y remove readline-devel ncurses-devel openssl-devel \
	&& yum -y groupremove "Development Tools" \
	&& yum clean all

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 500/udp 4500/udp

CMD ["/opt/vpnserver", "execsvc"]
