ARG BASE_IMAGE=centos:7
FROM ${BASE_IMAGE} AS builder

# CentOS 7 repositories have moved to Vault.
RUN sed -i -e 's/^mirrorlist=/#mirrorlist=/' \
        -e 's|^#baseurl=http://mirror.centos.org/centos/$releasever|baseurl=https://vault.centos.org/7.9.2009|' \
        /etc/yum.repos.d/CentOS-*.repo \
    && yum -y install ca-certificates curl tar gzip rpm-build redhat-rpm-config \
         gcc gcc-c++ make systemd openssl-devel libuuid-devel unzip perl \
         zlib-devel pcre-devel python \
    && yum clean all

ARG CMAKE_VERSION=3.27.9
RUN curl -fSL --retry 3 "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" -o /tmp/cmake.tar.gz \
    && mkdir -p /opt/cmake \
    && tar -xzf /tmp/cmake.tar.gz --strip-components=1 -C /opt/cmake \
    && rm /tmp/cmake.tar.gz
ENV PATH=/opt/cmake/bin:${PATH}

ARG BX_NGINX_VERSION
WORKDIR /root/rpmbuild
RUN mkdir -p SOURCES SPECS BUILD RPMS SRPMS BUILDROOT \
    && curl -fSL --retry 3 "https://repo.bitrix.info/dnf/SRPMS/bx-nginx-${BX_NGINX_VERSION}.src.rpm" -o /tmp/bx-nginx.src.rpm \
    && rpm -ivh --define '_topdir /root/rpmbuild' /tmp/bx-nginx.src.rpm \
    && rm /tmp/bx-nginx.src.rpm

ARG OPENSSL_VERSION=1.1.1w
RUN curl -fSL --retry 3 "https://www.openssl.org/source/old/1.1.1/openssl-${OPENSSL_VERSION}.tar.gz" \
        -o "SOURCES/openssl-${OPENSSL_VERSION}.tar.gz"
ARG PUSH_STREAM_VERSION=0.6.0
RUN curl -fSL --retry 3 "https://github.com/wandenberg/nginx-push-stream-module/archive/refs/tags/${PUSH_STREAM_VERSION}.tar.gz" \
        -o "SOURCES/nginx-push-stream-module-${PUSH_STREAM_VERSION}.tgz"
COPY prepare-spec.py /usr/local/bin/prepare-spec.py
ARG BUILD_DEBUG=0
RUN python /usr/local/bin/prepare-spec.py SPECS/bx-nginx.spec "${OPENSSL_VERSION}" "${BUILD_DEBUG}" "${PUSH_STREAM_VERSION}" \
    && rpmbuild -ba --define '_topdir /root/rpmbuild' --define 'dist .el7' SPECS/bx-nginx.spec \
    && mkdir -p /out/SRPMS \
    && cp RPMS/x86_64/*.rpm /out/ \
    && cp SRPMS/*.src.rpm /out/SRPMS/

RUN yum -y install openssl \
    && yum clean all \
    && rpm -Uvh /out/bx-nginx-[0-9]*.el7.x86_64.rpm \
    && nginx -V \
    && nginx -t \
    && printf '%s\n' 'events {}' 'http {' \
         'brotli on; push_stream_shared_memory_size 1m;' \
         'server { listen 127.0.0.1:8080;' \
         'location /pub { push_stream_publisher; push_stream_channels_path $arg_id; }' \
         'location /sub { push_stream_subscriber; push_stream_channels_path $arg_id; }' \
         '} }' > /tmp/nginx-modules.conf \
    && nginx -t -c /tmp/nginx-modules.conf
