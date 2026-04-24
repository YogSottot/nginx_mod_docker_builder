SHELL := /usr/bin/env bash

ifneq (,$(wildcard .env))
include .env
export $(shell sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' .env)
endif

ITERATION ?= 1
PACKAGE_NAME ?= zellij
PACKAGE_LICENSE ?= MIT
PACKAGE_URL ?= https://zellij.dev
MAINTAINER ?= Aram Drevekenin <aram@poor.dev>
SUMMARY ?= Terminal workspace and multiplexer

DESCRIPTION ?= A terminal workspace with batteries included
DESCRIPTION += Zellij is a workspace aimed at developers, ops-oriented
DESCRIPTION += people and anyone who loves the terminal. Similar programs are sometimes called
DESCRIPTION += Terminal Multiplexers.
DESCRIPTION += .
DESCRIPTION += Zellij is designed around the philosophy that one must not sacrifice simplicity
DESCRIPTION += for power, taking pride in its great experience out of the box as well as the
DESCRIPTION += advanced features it places at its users' fingertips.

ARCH_DEB ?= amd64
ARCH_RPM ?= x86_64

export ITERATION
export PACKAGE_NAME
export PACKAGE_LICENSE
export PACKAGE_URL
export MAINTAINER
export SUMMARY
export DESCRIPTION
export ARCH_DEB
export ARCH_RPM

.PHONY: all deb rpm \
	debian-12 debian-13 ubuntu-24.04 ubuntu-26.04 \
	rpm-generic repo-rpm clean print-env

all: deb rpm

deb: debian-12 debian-13 ubuntu-24.04 ubuntu-26.04

debian-12:
	DISTRO=debian VERSION_CODENAME=bookworm ./scripts/deb.sh

debian-13:
	DISTRO=debian VERSION_CODENAME=trixie ./scripts/deb.sh

ubuntu-24.04:
	DISTRO=ubuntu VERSION_CODENAME=noble ./scripts/deb.sh

ubuntu-26.04:
	DISTRO=ubuntu VERSION_CODENAME=resolute ./scripts/deb.sh

#rpm: rpm-generic repo-rpm
rpm: rpm-generic

rpm-generic:
	DIST_TAG=generic ./scripts/rpm.sh

#repo-rpm:
#	createrepo_c ./repo/generic/$(ARCH_RPM)

print-env:
	@echo "ITERATION=$(ITERATION)"
	@echo "PACKAGE_NAME=$(PACKAGE_NAME)"
	@echo "PACKAGE_LICENSE=$(PACKAGE_LICENSE)"
	@echo "PACKAGE_URL=$(PACKAGE_URL)"
	@echo "MAINTAINER=$(MAINTAINER)"
	@echo "SUMMARY=$(SUMMARY)"rpm_zellij
	@echo "DESCRIPTION=$(DESCRIPTION)"
	@echo "ARCH_DEB=$(ARCH_DEB)"
	@echo "ARCH_RPM=$(ARCH_RPM)"

clean: clean-pkg clean-src
	
clean-pkg:
	rm -rf ../deb/*/$(PACKAGE_NAME)*
	rm -rf ../rpm/generic/$(ARCH_RPM)/$(PACKAGE_NAME)*
	rm -rf ./rpmbuild

clean-src:
	rm -rf ../fpm/$(PACKAGE_NAME)
	rm -f ./$(PACKAGE_NAME)
	rm -f ./$(PACKAGE_NAME)-no-web-x86_64-unknown-linux-musl_*.tar.gz
