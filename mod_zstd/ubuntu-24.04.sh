#!/usr/bin/env bash
set -eo pipefail

mkdir -p ../module_$(basename "$0")
mkdir -p ../fpm/deb/noble
docker build --tag nginx_mod_docker_build --file Ubuntu-24.04 . &&  \
id=$(docker create nginx_mod_docker_build)
docker cp "${id}":/usr/local/nginx/modules/ ../module_$(basename "$0")/ && \
# zstd
docker cp "${id}":/usr/local/nginx/modules/ngx_http_zstd_filter_module.so ../fpm/mod_zstd/noble/usr/lib/nginx/modules/ && \
docker cp "${id}":/usr/local/nginx/modules/ngx_http_zstd_static_module.so ../fpm/mod_zstd/noble/usr/lib/nginx/modules/ && \
# delete image and container
docker rm -v "${id}" && \
# build libnginx-mod-http-zstd deb package
pushd ../fpm/mod_zstd/noble/ && \
fpm \
  -s dir -t deb \
  -p libnginx-mod-http-zstd_0.1.1-1.gbpf4ba115_noble_amd64.deb \
  --name libnginx-mod-http-zstd \
  --license bsd3 \
  --version 0.1.1-1.gbpf4ba115~noble \
  --architecture amd64 \
  --depends "nginx-abi-1.24.0-1, libc6 (>= 2.17)" \
  --description "NGINX module for ZSTD compression" \
  --maintainer "YogSottot  <7411302+YogSottot@users.noreply.github.com>" \
  --url "https://github.com/tokers/zstd-nginx-module" \
  --deb-changelog "debian/changelog.Debian" \
  --category httpd \
  --after-remove debian/postrm \
  --after-install debian/postinst \
  --before-remove debian/prerm \
  --package ../../deb/noble/ \
  usr/ && \
popd && \
docker image rm nginx_mod_docker_build
