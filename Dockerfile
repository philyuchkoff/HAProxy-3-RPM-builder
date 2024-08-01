FROM centos:8

RUN dnf install -y wget && yum -y groupinstall 'Development Tools'
RUN mkdir RPMS
RUN chmod -R 777 RPMS
RUN mkdir SPECS
RUN mkdir SOURCES
COPY Makefile Makefile
COPY SPECS/haproxy.spec SPECS/haproxy.spec
COPY SOURCES/* SOURCES/

CMD make NO_SUDO=1 USE_LUA=${USE_LUA:-0} USE_PROMETHEUS=${USE_PROMETHEUS:-0} RELEASE=${RELEASE:-1} && cp /rpmbuild/RPMS/x86_64/* /RPMS && cp /rpmbuild/SRPMS/* /RPMS
