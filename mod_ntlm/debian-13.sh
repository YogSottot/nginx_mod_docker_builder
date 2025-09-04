#!/usr/bin/env bash
set -eo pipefail

mkdir -p ../module_$(basename "$0")
mkdir -p ../fpm/deb/trixie
docker build --tag nginx_mod_docker_build --file Debian-13 . &&  \
id=$(docker create nginx_mod_docker_build)
docker cp "${id}":/usr/local/nginx/modules/ ../module_$(basename "$0")/ && \
# ntlm
docker cp "${id}":/usr/local/nginx/modules/ngx_http_upstream_ntlm_module.so ../fpm/mod_ntlm/trixie/usr/lib/nginx/modules/ && \
# delete image and container
docker rm -v "${id}" && \

pushd ../fpm/mod_ntlm/trixie/ && \
fpm \
  -s dir -t deb \
  -p libnginx-mod-http-ntlm_1.19.3-1.gbp3da77b0_trixie_amd64.deb \
  --name libnginx-mod-http-ntlm \
  --license bsd3 \
  --version 1.19.3-1.gbp3da77b0~trixie \
  --architecture amd64 \
  --depends "nginx-abi-1.26.3-1, libc6 (>= 2.4)" \
  --description "The NTLM module allows proxying requests with NTLM Authentication. The upstream connection is bound to the client connection once the client sends a request with the "Authorization" header field value starting with "Negotiate" or "NTLM". Further client requests will be proxied through the same upstream connection, keeping the authentication context." \
  --maintainer "YogSottot  <7411302+YogSottot@users.noreply.github.com>" \
  --url "https://github.com/gabihodoroaga/nginx-ntlm-module" \
  --deb-changelog "debian/changelog.Debian" \
  --category httpd \
  --after-remove debian/postrm \
  --after-install debian/postinst \
  --before-remove debian/prerm \
  --package ../../deb/trixie/ \
  usr/ && \
popd && \
docker image rm -f nginx_mod_docker_build 
