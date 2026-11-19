SHELL := /usr/bin/env bash

include .env
export $(shell sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=.*/\1/p' .env)

.PHONY: all rpm centos-7 print-env
all: rpm
rpm: centos-7

centos-7:
	bash ./rpm.sh

print-env:
	@cat .env
