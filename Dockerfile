FROM centos:8

RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
RUN dnf install -y wget vim pcre-devel make gcc openssl-devel rpm-build systemd-devel curl sed zlib-devel
RUN mkdir RPMS
RUN chmod -R 777 RPMS
RUN mkdir SPECS
RUN mkdir SOURCES
COPY Makefile Makefile
COPY SPECS/haproxy.spec SPECS/haproxy.spec
COPY SOURCES/* SOURCES/

CMD make NO_SUDO=1 USE_LUA=${USE_LUA:-0} USE_PROMETHEUS=${USE_PROMETHEUS:-0} RELEASE=${RELEASE:-1} && cp /rpmbuild/RPMS/x86_64/* /RPMS && cp /rpmbuild/SRPMS/* /RPMS

CMD make NO_SUDO=1 USE_PROMETHEUS=${USE_PROMETHEUS:-0} RELEASE=${RELEASE:-1} && cp /rpmbuild/RPMS/x86_64/* /RPMS && cp /rpmbuild/SRPMS/* /RPMS
