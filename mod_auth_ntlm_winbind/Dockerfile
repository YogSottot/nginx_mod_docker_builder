ARG BASE_IMAGE
FROM "${BASE_IMAGE}" AS builder

ARG MAINTAINER
LABEL maintainer="${MAINTAINER}"

ARG BUILD_DEPS
ARG SOURCE_ROOT
ARG SOURCE_DIR
ARG MODULE_NAME
ARG BUILD_DIR=/usr/share/tmp
ARG INSTALL_ROOT=/opt/mod_auth_ntlm_winbind

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends ${BUILD_DEPS} \
  && rm -rf /var/lib/apt/lists/*

COPY src/ "${BUILD_DIR}/src/"

RUN mkdir -p "${BUILD_DIR}/work" \
  && cp -a "${BUILD_DIR}/src/${SOURCE_ROOT}/${SOURCE_DIR}" "${BUILD_DIR}/work/${SOURCE_DIR}" \
  && cd "${BUILD_DIR}/work/${SOURCE_DIR}" \
  && patch -p1 < "${BUILD_DIR}/src/${SOURCE_ROOT}/bx-mod_auth_ntlm_winbind-20060510-connect_http10.patch" \
  && patch -p1 < "${BUILD_DIR}/src/${SOURCE_ROOT}/bx-mod_auth_ntlm_winbind-20070129-64bit.patch" \
  && autoconf \
  && apxs_bin="$(command -v apxs2 || command -v apxs)" \
  && httpd_bin="$(command -v apache2 || command -v httpd)" \
  && ./configure --with-apxs="${apxs_bin}" --with-apache="${httpd_bin}" \
  && make \
  && mkdir -p "${INSTALL_ROOT}/usr/lib/apache2/modules" \
  && make install DESTDIR="${INSTALL_ROOT}" \
  && apache_version="$(dpkg-query -W -f='${Version}\n' apache2)" \
  && apache_api_dep="$(dpkg-query -W -f='${Provides}\n' apache2-bin | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | awk '/^apache2-api-[0-9]+$/ { print; exit }')" \
  && test -n "${apache_version}" \
  && test -n "${apache_api_dep}" \
  && test -f "${INSTALL_ROOT}/usr/lib/apache2/modules/${MODULE_NAME}" \
  && printf '%s\n' "${apache_version}" > "${BUILD_DIR}/apache-version.txt" \
  && printf '%s\n' "${apache_api_dep}" > "${BUILD_DIR}/apache-api-depends.txt"
