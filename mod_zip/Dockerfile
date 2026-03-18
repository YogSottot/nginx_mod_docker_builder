ARG BASE_IMAGE
FROM "${BASE_IMAGE}" AS builder

ARG MAINTAINER
LABEL maintainer="${MAINTAINER}"

ARG SOURCE_REPO_URL
ARG SOURCE_DIR
ARG MOD_ZIP_VERSION
ARG NGINX_VERSION
ARG BUILD_DEPS
ARG BUILD_DIR=/usr/share/tmp

RUN apt update && apt install -y --no-install-recommends ${BUILD_DEPS} \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${BUILD_DIR}"

RUN cd "${BUILD_DIR}" \
  && wget "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
  && tar zxf "nginx-${NGINX_VERSION}.tar.gz" \
  && rm "nginx-${NGINX_VERSION}.tar.gz"

RUN cd "${BUILD_DIR}" \
  && git clone --depth 2 --recursive "${SOURCE_REPO_URL}" "${SOURCE_DIR}" \
  && cd "${SOURCE_DIR}" \
  && git checkout "${MOD_ZIP_VERSION}"

RUN cd "${BUILD_DIR}/nginx-${NGINX_VERSION}" \
  && ./configure --with-compat --add-dynamic-module="../${SOURCE_DIR}" \
  && make \
  && make install
