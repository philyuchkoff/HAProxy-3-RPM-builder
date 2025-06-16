HOME=$(shell pwd)
MAINVERSION?=3.2
LUA_VERSION?=5.4.8
USE_LUA?=0
NO_SUDO?=0
USE_PROMETHEUS?=0
VERSION=$(shell wget -qO- https://git.haproxy.org/git/haproxy-${MAINVERSION}.git/refs/tags/ | sed -n 's:.*>\(.*\)</a>.*:\1:p' | sed 's/^.//' | sort -rV | head -1)
ifeq ("${VERSION}","./")
	VERSION="${MAINVERSION}.0"
endif
RELEASE?=1

# Определяем SUDO в зависимости от NO_SUDO
SUDO := $(if $(filter 1,$(NO_SUDO)),,sudo)

all: build

install_prereq:
	$(SUDO) dnf install -y pcre-devel make gcc openssl-devel rpm-build systemd-devel wget sed zlib-devel

clean:
	$(SUDO) rm -f ./SOURCES/haproxy-${VERSION}.tar.gz
	$(SUDO) rm -rf ./lua-${LUA_VERSION}*
	$(SUDO) rm -rf ./rpmbuild
	$(SUDO) mkdir -p ./rpmbuild/SPECS/ ./rpmbuild/SOURCES/ ./rpmbuild/RPMS/ ./rpmbuild/SRPMS/

download-upstream:
	$(SUDO) wget https://www.haproxy.org/download/${MAINVERSION}/src/haproxy-${VERSION}.tar.gz -O ./SOURCES/haproxy-${VERSION}.tar.gz

build_lua:
	$(SUDO) dnf install -y readline-devel
	$(SUDO) wget --no-check-certificate https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz
	$(SUDO) tar xzf lua-${LUA_VERSION}.tar.gz
	cd lua-${LUA_VERSION} && \
	$(SUDO) $(MAKE) clean && \
	$(SUDO) $(MAKE) MYCFLAGS=-fPIC linux test && \
	$(SUDO) $(MAKE) install && \
	cd ..

build_stages := install_prereq clean download-upstream
ifeq ($(USE_LUA),1)
	build_stages += build_lua
endif

build-docker:
	docker build -t haproxy-rpm-builder:latest -f Dockerfile .

run-docker: build-docker
	mkdir -p RPMS
ifeq ($(USE_LUA),1)
	docker run -e USE_LUA=${USE_LUA} -e USE_PROMETHEUS=${USE_PROMETHEUS} -e RELEASE=${RELEASE} --volume $(HOME)/RPMS:/RPMS --rm haproxy-rpm-builder:latest
else
	docker run -e USE_PROMETHEUS=${USE_PROMETHEUS} -e RELEASE=${RELEASE} --volume $(HOME)/RPMS:/RPMS --rm haproxy-rpm-builder:latest
endif

build: $(build_stages)
	$(SUDO) cp -r ./SPECS/* ./rpmbuild/SPECS/ || true
	$(SUDO) cp -r ./SOURCES/* ./rpmbuild/SOURCES/ || true
	$(SUDO) rpmbuild -ba SPECS/haproxy.spec \
	--define "mainversion ${MAINVERSION}" \
	--define "version ${VERSION}" \
	--define "release ${RELEASE}" \
	--define "_topdir %(pwd)/rpmbuild" \
	--define "_builddir %{_topdir}/BUILD" \
	--define "_buildroot %{_topdir}/BUILDROOT" \
	--define "_rpmdir %{_topdir}/RPMS" \
	--define "_srcrpmdir %{_topdir}/SRPMS" \
	--define "_use_lua ${USE_LUA}" \
	--define "_use_prometheus ${USE_PROMETHEUS}"
