#!/usr/bin/env bash
set -eo pipefail

mkdir -p module_$(basename "$0")
#docker build --tag nginx_mod_docker_build --file Ubuntu-24.04 . &&  \
id=$(docker create nginx_mod_docker_build)
docker cp $id:/usr/local/nginx/modules/ module_$(basename "$0")/ && \
docker rm -v $id && \
docker image rm nginx_mod_docker_build
