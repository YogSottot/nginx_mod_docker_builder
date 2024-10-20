#!/usr/bin/env bash
set -eo pipefail

mkdir -p module_$(basename "$0")
mkdir -p fpm/deb/noble
docker build --tag nginx_mod_docker_build --file Ubuntu-24.04 . &&  \
id=$(docker create nginx_mod_docker_build)
docker cp "${id}":/usr/local/nginx/modules/ module_$(basename "$0")/ && \
# zip
docker cp "${id}":/usr/local/nginx/modules/ngx_http_zip_module.so fpm/mod_zip/noble/usr/lib/nginx/modules/ && \
# ntlm
docker cp "${id}":/usr/local/nginx/modules/ngx_http_upstream_ntlm_module.so fpm/mod_ntlm/noble/usr/lib/nginx/modules/ && \
# zstd
docker cp "${id}":/usr/local/nginx/modules/ngx_http_zstd_filter_module.so fpm/mod_zstd/noble/usr/lib/nginx/modules/ && \
docker cp "${id}":/usr/local/nginx/modules/ngx_http_zstd_filter_module.so fpm/mod_zstd/noble/usr/lib/nginx/modules/ && \
# delete image and container
docker rm -v "${id}" && \
docker image rm nginx_mod_docker_build && \
# build libnginx-mod-http-zip deb package
pushd fpm/mod_zip/noble/ && \
fpm \
  -s dir -t deb \
  -p libnginx-mod-http-zip_1.3.0-1.gbp8e65b82_noble_amd64.deb \
  --name libnginx-mod-http-zip \
  --license bsd3 \
  --version 1.3.0-1.gbp8e65b82~noble \
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
  --package ../../deb/noble/ \
  usr/ && \
popd && \
# build libnginx-mod-http-ntlm deb package
pushd fpm/mod_ntlm/noble/ && \
fpm \
  -s dir -t deb \
  -p libnginx-mod-http-ntlm_1.19.3-1.gbp3da77b0_noble_amd64.deb \
  --name libnginx-mod-http-ntlm \
  --license bsd3 \
  --version 1.19.3-1.gbp3da77b0~noble \
  --architecture amd64 \
  --depends "nginx-abi-1.22.1-7, libc6 (>= 2.4)" \
  --description "The NTLM module allows proxying requests with NTLM Authentication. The upstream connection is bound to the client connection once the client sends a request with the "Authorization" header field value starting with "Negotiate" or "NTLM". Further client requests will be proxied through the same upstream connection, keeping the authentication context." \
  --maintainer "YogSottot  <7411302+YogSottot@users.noreply.github.com>" \
  --url "https://github.com/gabihodoroaga/nginx-ntlm-module" \
  --deb-changelog "debian/changelog.Debian" \
  --category httpd \
  --after-remove debian/postrm \
  --after-install debian/postinst \
  --before-remove debian/prerm \
  --package ../../deb/noble/ \
  usr/&& \
popd && \
# build libnginx-mod-http-zstd deb package
pushd fpm/mod_zstd/noble/ && \
fpm \
  -s dir -t deb \
  -p libnginx-mod-http-zstd_0.1.1-1.gbpf4ba115_noble_amd64.deb \
  --name libnginx-mod-http-zstd \
  --license bsd3 \
  --version 0.1.1-1.gbpf4ba115~noble \
  --architecture amd64 \
  --depends "nginx-abi-1.22.1-7, libc6 (>= 2.4)" \
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
popd
