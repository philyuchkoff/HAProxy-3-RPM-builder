HOME := $(abspath $(shell pwd))
MAINVERSION ?= 3.2
LUA_VERSION ?= 5.4.8
USE_LUA ?= 0
NO_SUDO ?= 0
USE_PROMETHEUS ?= 0
RELEASE ?= 1

# Автоматическое определение последней версии HAProxy
VERSION := $(shell wget -qO- https://git.haproxy.org/git/haproxy-${MAINVERSION}.git/refs/tags/ | \
            grep -oP '(?<=>v?)[^<]+' | sort -rV | head -1)
VERSION := $(if $(VERSION),$(VERSION),${MAINVERSION}.0)

# Определение SUDO
SUDO := $(if $(filter 1,$(NO_SUDO)),,sudo)

# Основные зависимости
BASE_DEPS := pcre-devel make gcc openssl-devel rpm-build systemd-devel wget sed zlib-devel
LUA_DEPS := readline-devel

# Этапы сборки
BUILD_STAGES := install_prereq clean download-upstream
ifeq ($(USE_LUA),1)
    BUILD_STAGES += build_lua
endif

.PHONY: all install_prereq clean download-upstream build_lua build-docker run-docker build

all: build

install_prereq:
	$(SUDO) dnf install -y $(BASE_DEPS)

clean:
	$(SUDO) rm -f ./SOURCES/haproxy-${VERSION}.tar.gz
	$(SUDO) rm -rf ./lua-${LUA_VERSION}*
	$(SUDO) rm -rf ./rpmbuild
	$(SUDO) mkdir -p ./rpmbuild/{SPECS,SOURCES,RPMS,SRPMS}

download-upstream:
	$(SUDO) wget https://www.haproxy.org/download/${MAINVERSION}/src/haproxy-${VERSION}.tar.gz \
	          -O ./SOURCES/haproxy-${VERSION}.tar.gz

build_lua:
	$(SUDO) dnf install -y $(LUA_DEPS)
	$(SUDO) wget --no-check-certificate https://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz
	$(SUDO) tar xzf lua-${LUA_VERSION}.tar.gz
	cd lua-${LUA_VERSION} && \
	$(SUDO) $(MAKE) clean && \
	$(SUDO) $(MAKE) MYCFLAGS=-fPIC linux test && \
	$(SUDO) $(MAKE) install
	$(SUDO) rm -f lua-${LUA_VERSION}.tar.gz

build-docker:
	docker build -t haproxy-rpm-builder:latest -f Dockerfile .

run-docker: build-docker
	mkdir -p RPMS
	docker run -e USE_LUA=$(USE_LUA) \
	           -e USE_PROMETHEUS=$(USE_PROMETHEUS) \
	           -e RELEASE=$(RELEASE) \
	           --volume $(HOME)/RPMS:/RPMS \
	           --rm haproxy-rpm-builder:latest

build: $(BUILD_STAGES)
	$(SUDO) cp -r ./SPECS/* ./rpmbuild/SPECS/ 2>/dev/null || true
	$(SUDO) cp -r ./SOURCES/* ./rpmbuild/SOURCES/ 2>/dev/null || true
	$(SUDO) rpmbuild -ba SPECS/haproxy.spec \
	    --define "mainversion $(MAINVERSION)" \
	    --define "version $(VERSION)" \
	    --define "release $(RELEASE)" \
	    --define "_topdir $(HOME)/rpmbuild" \
	    --define "_builddir %{_topdir}/BUILD" \
	    --define "_buildroot %{_topdir}/BUILDROOT" \
	    --define "_rpmdir %{_topdir}/RPMS" \
	    --define "_srcrpmdir %{_topdir}/SRPMS" \
	    --define "_use_lua $(USE_LUA)" \
	    --define "_use_prometheus $(USE_PROMETHEUS)"
