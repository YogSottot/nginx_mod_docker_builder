ARG BASE_IMAGE=almalinux:9
FROM ${BASE_IMAGE} AS builder

ARG MAINTAINER
LABEL maintainer="${MAINTAINER}"
ARG NGINX_VERSION=1.26.3
ARG NGINX_STREAM=1.26
ARG MOD_GEOIP2_VERSION=445df24ef3781e488cee3dfe8a1e111997fc1dfe
WORKDIR /usr/share/tmp

RUN dnf -y install dnf-plugins-core \
    && dnf config-manager --set-enabled crb \
    && dnf -y module reset nginx \
    && dnf -y module enable nginx:${NGINX_STREAM} \
    && dnf -y install "nginx-${NGINX_VERSION}" gcc make curl-minimal tar gzip \
         pcre2-devel zlib-devel openssl-devel libmaxminddb-devel \
    && test "$(rpm -q --qf '%{VERSION}' nginx-core)" = "${NGINX_VERSION}" \
    && rpm -q --qf '%{EPOCHNUM}:%{VERSION}-%{RELEASE}\n' nginx-core > nginx-package-version.txt \
    && dnf clean all

RUN curl -fsSL "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.gz \
    && tar -xzf nginx.tar.gz \
    && curl -fsSL "github.com/leev/ngx_http_geoip2_module/archive/${MOD_GEOIP2_VERSION}.tar.gz" -o geoip2.tar.gz \
    && tar -xzf geoip2.tar.gz

# Build only the HTTP module. Verify its ABI against the actual AppStream binary.
RUN cd "nginx-${NGINX_VERSION}" \
    && ./configure --with-compat --with-http_ssl_module \
         --add-dynamic-module="../ngx_http_geoip2_module-${MOD_GEOIP2_VERSION}" \
    && make -j"$(nproc)" modules \
    && install -Dm0755 objs/ngx_http_geoip2_module.so /out/usr/lib64/nginx/modules/ngx_http_geoip2_module.so \
    && mkdir -p /out/usr/share/nginx/modules /out/usr/share/doc/nginx-mod-http-geoip2 \
    && printf '%s\n' 'load_module "/usr/lib64/nginx/modules/ngx_http_geoip2_module.so";' \
         > /out/usr/share/nginx/modules/mod-http-geoip2.conf \
    && cp ../ngx_http_geoip2_module-${MOD_GEOIP2_VERSION}/LICENSE \
         ../ngx_http_geoip2_module-${MOD_GEOIP2_VERSION}/README.md /out/usr/share/doc/nginx-mod-http-geoip2/ \
    && install -Dm0755 objs/ngx_http_geoip2_module.so /usr/lib64/nginx/modules/ngx_http_geoip2_module.so \
    && printf '%s\n' 'load_module /usr/lib64/nginx/modules/ngx_http_geoip2_module.so;' \
         'error_log stderr; pid /tmp/nginx-geoip2.pid; events {} http {}' > /tmp/nginx-geoip2.conf \
    && nginx -t -c /tmp/nginx-geoip2.conf
