SHELL := /usr/bin/env bash

include .env
export $(shell sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' .env)

.PHONY: all rpm almalinux-9 print-env

all: rpm
rpm: almalinux-9

almalinux-9:
	bash ./rpm.sh

print-env:
	@echo "BASE_IMAGE=$(BASE_IMAGE)"
	@echo "NGINX_VERSION=$(NGINX_VERSION)"
	@echo "NGINX_STREAM=$(NGINX_STREAM)"
	@echo "MOD_GEOIP2_VERSION=$(MOD_GEOIP2_VERSION)"
	@echo "PACKAGE_NAME=$(PACKAGE_NAME)"
	@echo "ARCH_RPM=$(ARCH_RPM)"
	@echo "DOCKER_PLATFORM=$(DOCKER_PLATFORM)"
