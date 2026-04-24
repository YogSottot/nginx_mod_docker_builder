ARG BASE_IMAGE
FROM "${BASE_IMAGE}" AS builder

ARG MAINTAINER
LABEL maintainer="${MAINTAINER}"

ARG SOURCE_REPO_URL
ARG SOURCE_DIR
ARG MOD_ZSTD_VERSION
ARG ZSTD_VERSION
ARG BUILD_DEPS
ARG BUILD_DIR=/usr/share/tmp
ARG NGINX_PACKAGE=nginx-core

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends ${BUILD_DEPS} "${NGINX_PACKAGE}" \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${BUILD_DIR}" \
  && nginx_package_version="$(dpkg-query -W -f='${Version}\n' "${NGINX_PACKAGE}")" \
  && nginx_abi_dep="$(dpkg-query -W -f='${Provides}\n' "${NGINX_PACKAGE}" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | awk '/^nginx-abi-/ { print; exit }')" \
  && if [ -z "${nginx_abi_dep}" ]; then \
       nginx_abi_dep="$(apt-cache show libnginx-mod-stream 2>/dev/null | awk -F': ' '/^Depends:/ { print $2; exit }' | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | awk '/^nginx-abi-/ { print; exit }')"; \
     fi \
  && nginx_source_version="${nginx_package_version#*:}" \
  && nginx_source_version="${nginx_source_version%%-*}" \
  && test -n "${nginx_package_version}" \
  && test -n "${nginx_source_version}" \
  && test -n "${nginx_abi_dep}" \
  && printf '%s\n' "${nginx_package_version}" > "${BUILD_DIR}/nginx-package-version.txt" \
  && printf '%s\n' "${nginx_source_version}" > "${BUILD_DIR}/nginx-source-version.txt" \
  && printf '%s\n' "${nginx_abi_dep}" > "${BUILD_DIR}/nginx-abi-depends.txt"

RUN cd "${BUILD_DIR}" \
  && NGINX_SOURCE_VERSION="$(cat "${BUILD_DIR}/nginx-source-version.txt")" \
  && wget "https://nginx.org/download/nginx-${NGINX_SOURCE_VERSION}.tar.gz" \
  && tar zxf "nginx-${NGINX_SOURCE_VERSION}.tar.gz" \
  && rm "nginx-${NGINX_SOURCE_VERSION}.tar.gz"

RUN cd "${BUILD_DIR}" \
  && git clone --depth 2 --recursive "${SOURCE_REPO_URL}" "${SOURCE_DIR}" \
  && cd "${SOURCE_DIR}" \
  && git checkout "${MOD_ZSTD_VERSION}"

RUN cd /opt \
  && wget "https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz" \
  && tar xfz "zstd-${ZSTD_VERSION}.tar.gz" \
  && cd "zstd-${ZSTD_VERSION}" \
  && CFLAGS="-O3 -fPIC" make \
  && make install

RUN NGINX_SOURCE_VERSION="$(cat "${BUILD_DIR}/nginx-source-version.txt")" \
  && cd "${BUILD_DIR}/nginx-${NGINX_SOURCE_VERSION}" \
  && ./configure --with-compat --add-dynamic-module="../${SOURCE_DIR}" \
  && make \
  && make install
