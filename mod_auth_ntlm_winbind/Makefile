SHELL := /usr/bin/env bash

ifneq (,$(wildcard .env))
include .env
export $(shell sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' .env)
endif

.PHONY: all deb debian-12 debian-13 ubuntu-24.04 print-env clean

all: deb

deb: debian-12 debian-13 ubuntu-24.04

debian-12:
	TARGET=DEBIAN_12 bash ./deb.sh

debian-13:
	TARGET=DEBIAN_13 bash ./deb.sh

ubuntu-24.04:
	TARGET=UBUNTU_24_04 bash ./deb.sh

print-env:
	@echo "PACKAGE_NAME=$(PACKAGE_NAME)"
	@echo "PACKAGE_LICENSE=$(PACKAGE_LICENSE)"
	@echo "PACKAGE_URL=$(PACKAGE_URL)"
	@echo "MAINTAINER=$(MAINTAINER)"
	@echo "ARCH_DEB=$(ARCH_DEB)"
	@echo "PACKAGE_VERSION=$(PACKAGE_VERSION)"
	@echo "ITERATION=$(ITERATION)"
	@echo "CONFIG_FILE=$(CONFIG_FILE)"
	@echo "DEPENDS=$(DEPENDS)"

clean: clean-pkg clean-src
	
clean-pkg:
	rm -rf ../deb/*/$(PACKAGE_NAME)*

clean-src:
	rm -rf ../fpm/$(PACKAGE_NAME)
