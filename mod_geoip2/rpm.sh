#!/usr/bin/env bash
set -euo pipefail

for name in BASE_IMAGE NGINX_VERSION NGINX_STREAM MOD_GEOIP2_VERSION PACKAGE_NAME PACKAGE_LICENSE PACKAGE_URL MAINTAINER ITERATION ARCH_RPM DOCKER_PLATFORM DOCKER_IMAGE; do
    if [ -z "${!name:-}" ]; then
        echo "Missing required variable: ${name}; run make almalinux-9" >&2
        exit 1
    fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
STAGE_DIR="${REPO_ROOT}/fpm/${PACKAGE_NAME}/almalinux-9"
OUTPUT_DIR="${REPO_ROOT}/rpm/almalinux-9/${ARCH_RPM}"
BUILD_IMAGE="${DOCKER_IMAGE}:almalinux-9"
container_id=""
metadata_dir="$(mktemp -d)"
cleanup() {
    if [ -n "${container_id}" ]; then
        docker rm -v "${container_id}" >/dev/null || true
    fi
    rm -rf "${metadata_dir}"
}
trap cleanup EXIT

docker build --platform "${DOCKER_PLATFORM}" --tag "${BUILD_IMAGE}" \
    --file "${SCRIPT_DIR}/Dockerfile" \
    --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
    --build-arg "MAINTAINER=${MAINTAINER}" \
    --build-arg "NGINX_VERSION=${NGINX_VERSION}" \
    --build-arg "NGINX_STREAM=${NGINX_STREAM}" \
    --build-arg "MOD_GEOIP2_VERSION=${MOD_GEOIP2_VERSION}" "${SCRIPT_DIR}"

container_id="$(docker create --platform "${DOCKER_PLATFORM}" "${BUILD_IMAGE}")"
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}" "${OUTPUT_DIR}"
docker cp "${container_id}:/out/." "${STAGE_DIR}/"
docker cp "${container_id}:/usr/share/tmp/nginx-package-version.txt" "${metadata_dir}/nginx-package-version.txt"
NGINX_PACKAGE_VERSION="$(tr -d '\r\n' < "${metadata_dir}/nginx-package-version.txt")"
test -n "${NGINX_PACKAGE_VERSION}"

fpm --force -s dir -t rpm -C "${STAGE_DIR}" \
    --name "${PACKAGE_NAME}" --version "${MOD_GEOIP2_VERSION}" \
    --iteration "${ITERATION}.el9" --architecture "${ARCH_RPM}" \
    --license "${PACKAGE_LICENSE}" --url "${PACKAGE_URL}" --maintainer "${MAINTAINER}" \
    --description "GeoIP2 HTTP module for AlmaLinux 9 AppStream nginx ${NGINX_VERSION}" \
    --category httpd --depends "nginx-core = ${NGINX_PACKAGE_VERSION}" \
    --depends 'libmaxminddb.so.0()(64bit)' --depends 'libc.so.6()(64bit)' \
    --rpm-use-file-permissions --rpm-user root --rpm-group root \
    --package "${OUTPUT_DIR}/${PACKAGE_NAME}-${MOD_GEOIP2_VERSION}-${ITERATION}.el9.${ARCH_RPM}.rpm" usr/
