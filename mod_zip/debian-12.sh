#!/usr/bin/env bash
set -eo pipefail

mkdir -p ../module_$(basename "$0")
mkdir -p ../fpm/deb/bookworm
docker build --tag nginx_mod_docker_build --file Debian-12 . &&  \
id=$(docker create nginx_mod_docker_build)
docker cp "${id}":/usr/local/nginx/modules/ ../module_$(basename "$0")/ && \
# zip
docker cp "${id}":/usr/local/nginx/modules/ngx_http_zip_module.so ../fpm/mod_zip/bookworm/usr/lib/nginx/modules/ && \
# delete image and container
docker rm -v "${id}" && \
# build libnginx-mod-http-zip deb package
pushd ../fpm/mod_zip/bookworm/ && \
fpm \
  -s dir -t deb \
  -p libnginx-mod-http-zip_1.3.0-2.gbp4aa963c_bookworm_amd64.deb \
  --name libnginx-mod-http-zip \
  --license bsd3 \
  --version 1.3.0-2.gbp4aa963c~bookworm \
  --architecture amd64 \
  --depends "nginx-abi-1.22.1-7, libc6 (>= 2.4)" \
  --description "mod_zip assembles ZIP archives dynamically. It can stream component files from upstream servers with nginx's native proxying code, so that the process never takes up more than a few KB of RAM at a time, even while assembling archives that are (potentially) gigabytes in size." \
  --url "https://github.com/evanmiller/mod_zip" \
  --maintainer "YogSottot  <7411302+YogSottot@users.noreply.github.com>" \
  --deb-changelog "debian/changelog.Debian" \
  --category httpd \
  --after-remove debian/postrm \
  --after-install debian/postinst \
  --before-remove debian/prerm \
  --package ../../deb/bookworm/ \
  usr/ && \
popd && \
docker image rm -f nginx_mod_docker_build
