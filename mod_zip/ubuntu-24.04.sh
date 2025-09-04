#!/usr/bin/env bash
set -eo pipefail

mkdir -p ../module_$(basename "$0")
mkdir -p ../fpm/deb/noble
docker build --tag nginx_mod_docker_build --file Ubuntu-24.04 . &&  \
id=$(docker create nginx_mod_docker_build)
docker cp "${id}":/usr/local/nginx/modules/ ../module_$(basename "$0")/ && \
# zip
docker cp "${id}":/usr/local/nginx/modules/ngx_http_zip_module.so ../fpm/mod_zip/noble/usr/lib/nginx/modules/ && \
# delete image and container
docker rm -v "${id}" && \
# build libnginx-mod-http-zip deb package
pushd ../fpm/mod_zip/noble/ && \
fpm \
  -s dir -t deb \
  -p libnginx-mod-http-zip_1.3.0-2.gbp4aa963c_noble_amd64.deb \
  --name libnginx-mod-http-zip \
  --license bsd3 \
  --version 1.3.0-2.gbp4aa963c~noble \
  --architecture amd64 \
  --depends "nginx-abi-1.24.0-1, libc6 (>= 2.17)" \
  --description "mod_zip assembles ZIP archives dynamically. It can stream component files from upstream servers with nginx's native proxying code, so that the process never takes up more than a few KB of RAM at a time, even while assembling archives that are (potentially) gigabytes in size." \
  --url "https://github.com/evanmiller/mod_zip" \
  --maintainer "YogSottot  <7411302+YogSottot@users.noreply.github.com>" \
  --deb-changelog "debian/changelog.Debian" \
  --category httpd \
  --after-remove debian/postrm \
  --after-install debian/postinst \
  --before-remove debian/prerm \
  --package ../../deb/noble/ \
  usr/ && \
popd && \
docker image rm -f nginx_mod_docker_build
