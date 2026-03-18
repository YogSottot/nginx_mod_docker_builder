SHELL := /usr/bin/env bash

ifneq (,$(wildcard .env))
include .env
export $(shell sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' .env)
endif

.PHONY: all deb debian-12 debian-13 ubuntu-24.04 print-env clean

all: deb

deb: debian-12 debian-13 ubuntu-24.04

debian-12:
	TARGET=DEBIAN_12 BASE_IMAGE="$(DEBIAN_12_BASE_IMAGE)" bash ./deb.sh

debian-13:
	TARGET=DEBIAN_13 BASE_IMAGE="$(DEBIAN_13_BASE_IMAGE)" bash ./deb.sh

ubuntu-24.04:
	TARGET=UBUNTU_24_04 BASE_IMAGE="$(UBUNTU_24_04_BASE_IMAGE)" bash ./deb.sh

print-env:
	@echo "PACKAGE_NAME=$(PACKAGE_NAME)"
	@echo "PACKAGE_LICENSE=$(PACKAGE_LICENSE)"
	@echo "PACKAGE_URL=$(PACKAGE_URL)"
	@echo "SOURCE_REPO_URL=$(SOURCE_REPO_URL)"
	@echo "SOURCE_DIR=$(SOURCE_DIR)"
	@echo "MAINTAINER=$(MAINTAINER)"
	@echo "ARCH_DEB=$(ARCH_DEB)"
	@echo "DOCKER_IMAGE=$(DOCKER_IMAGE)"
	@echo "MODULE_NAMES=$(MODULE_NAMES)"
	@echo "MODULE_CONF_NAME=$(MODULE_CONF_NAME)"
	@echo "PACKAGE_VERSION=$(PACKAGE_VERSION)"
	@echo "MOD_ZSTD_VERSION=$(MOD_ZSTD_VERSION)"
	@echo "ZSTD_VERSION=$(ZSTD_VERSION)"
	@echo "ITERATION=$(ITERATION)"
	@echo "DEBIAN_12_BASE_IMAGE=$(DEBIAN_12_BASE_IMAGE)"
	@echo "DEBIAN_13_BASE_IMAGE=$(DEBIAN_13_BASE_IMAGE)"
	@echo "UBUNTU_24_04_BASE_IMAGE=$(UBUNTU_24_04_BASE_IMAGE)"

clean: clean-pkg clean-src

clean-pkg:
	rm -rf ../deb/*/$(PACKAGE_NAME)*

clean-src:
	rm -rf ../fpm/$(PACKAGE_NAME)
