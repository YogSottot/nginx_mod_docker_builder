#!/usr/bin/env bash
set -euo pipefail

for name in BASE_IMAGE BX_NGINX_VERSION OPENSSL_VERSION PUSH_STREAM_VERSION CMAKE_VERSION BUILD_DEBUG ARCH_RPM DOCKER_PLATFORM DOCKER_IMAGE; do
    if [ -z "${!name:-}" ]; then
        echo "Missing required variable: ${name}; run make centos-7" >&2
        exit 1
    fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/rpm/centos-7/${ARCH_RPM}"
BUILD_IMAGE="${DOCKER_IMAGE}:centos-7"
container_id=""
cleanup() {
    if [ -n "${container_id}" ]; then
        docker rm -v "${container_id}" >/dev/null || true
    fi
}
trap cleanup EXIT

docker build --platform "${DOCKER_PLATFORM}" --tag "${BUILD_IMAGE}" \
    --file "${SCRIPT_DIR}/Dockerfile" \
    --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
    --build-arg "BX_NGINX_VERSION=${BX_NGINX_VERSION}" \
    --build-arg "OPENSSL_VERSION=${OPENSSL_VERSION}" \
    --build-arg "PUSH_STREAM_VERSION=${PUSH_STREAM_VERSION}" \
    --build-arg "CMAKE_VERSION=${CMAKE_VERSION}" \
    --build-arg "BUILD_DEBUG=${BUILD_DEBUG}" "${SCRIPT_DIR}"

container_id="$(docker create --platform "${DOCKER_PLATFORM}" "${BUILD_IMAGE}")"
mkdir -p "${OUTPUT_DIR}"
docker cp "${container_id}:/out/." "${OUTPUT_DIR}/"
printf 'RPM packages: %s\n' "${OUTPUT_DIR}"
