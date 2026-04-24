#!/usr/bin/env bash
set -euo pipefail

: "${TARGET:?TARGET is required}"
: "${PACKAGE_NAME:?PACKAGE_NAME is required}"
: "${PACKAGE_LICENSE:?PACKAGE_LICENSE is required}"
: "${PACKAGE_URL:?PACKAGE_URL is required}"
: "${SOURCE_REPO_URL:?SOURCE_REPO_URL is required}"
: "${SOURCE_DIR:?SOURCE_DIR is required}"
: "${MAINTAINER:?MAINTAINER is required}"
: "${ARCH_DEB:?ARCH_DEB is required}"
: "${BASE_IMAGE:?BASE_IMAGE is required}"
: "${DOCKER_IMAGE:?DOCKER_IMAGE is required}"
: "${MODULE_NAME:?MODULE_NAME is required}"
: "${MODULE_CONF_NAME:?MODULE_CONF_NAME is required}"
: "${MODULE_CONF_CONTENT:?MODULE_CONF_CONTENT is required}"
: "${DESCRIPTION:?DESCRIPTION is required}"
: "${PACKAGE_VERSION:?PACKAGE_VERSION is required}"
: "${MOD_ZIP_VERSION:?MOD_ZIP_VERSION is required}"
: "${ITERATION:?ITERATION is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

for suffix in DISTRO VERSION_CODENAME LIBC_DEPENDS BUILD_DEPS; do
    var_name="${TARGET}_${suffix}"
    value="${!var_name:-}"
    if [ -z "${value}" ]; then
        echo "Missing required variable: ${var_name}" >&2
        exit 1
    fi
    export "${suffix}=${value}"
done

STAGE_DIR="${REPO_ROOT}/fpm/${PACKAGE_NAME}/${VERSION_CODENAME}"
OUTPUT_DIR="${REPO_ROOT}/deb/${VERSION_CODENAME}"
DOC_DIR="${STAGE_DIR}/usr/share/doc/${PACKAGE_NAME}"
MODULES_DIR="${STAGE_DIR}/usr/lib/nginx/modules"
MODULES_AVAILABLE_DIR="${STAGE_DIR}/usr/share/nginx/modules-available"
DEBIAN_DIR="${STAGE_DIR}/debian"
HOOKS_SOURCE_DIR="${REPO_ROOT}/fpm/${PACKAGE_NAME}/${VERSION_CODENAME}/debian"
CONFS_SOURCE_DIR="${REPO_ROOT}/fpm/${PACKAGE_NAME}/${VERSION_CODENAME}/usr/share/nginx/modules-available"
BUILD_IMAGE="${DOCKER_IMAGE}:${VERSION_CODENAME}"
BUILD_METADATA_DIR="/usr/share/tmp"

rm -rf "${STAGE_DIR}"
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${DOC_DIR}" "${MODULES_DIR}" "${MODULES_AVAILABLE_DIR}" "${DEBIAN_DIR}"

docker build \
  --tag "${BUILD_IMAGE}" \
  --file "${SCRIPT_DIR}/Dockerfile" \
  --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
  --build-arg "MAINTAINER=${MAINTAINER}" \
  --build-arg "SOURCE_REPO_URL=${SOURCE_REPO_URL}" \
  --build-arg "SOURCE_DIR=${SOURCE_DIR}" \
  --build-arg "MOD_ZIP_VERSION=${MOD_ZIP_VERSION}" \
  --build-arg "BUILD_DEPS=${BUILD_DEPS}" \
  "${SCRIPT_DIR}"

container_id="$(docker create "${BUILD_IMAGE}")"
metadata_dir="$(mktemp -d)"
cleanup() {
    if [ -n "${container_id:-}" ]; then
        docker rm -v "${container_id}" >/dev/null
    fi
    if [ -n "${metadata_dir:-}" ] && [ -d "${metadata_dir}" ]; then
        rm -rf "${metadata_dir}"
    fi
    docker image rm -f "${BUILD_IMAGE}" >/dev/null
}
trap cleanup EXIT

docker cp "${container_id}:/usr/local/nginx/modules/${MODULE_NAME}" "${MODULES_DIR}/${MODULE_NAME}"
docker cp "${container_id}:${BUILD_METADATA_DIR}/nginx-package-version.txt" "${metadata_dir}/nginx-package-version.txt"
docker cp "${container_id}:${BUILD_METADATA_DIR}/nginx-source-version.txt" "${metadata_dir}/nginx-source-version.txt"
docker cp "${container_id}:${BUILD_METADATA_DIR}/nginx-abi-depends.txt" "${metadata_dir}/nginx-abi-depends.txt"

NGINX_PACKAGE_VERSION="$(tr -d '\r\n' < "${metadata_dir}/nginx-package-version.txt")"
NGINX_SOURCE_VERSION="$(tr -d '\r\n' < "${metadata_dir}/nginx-source-version.txt")"
NGINX_ABI_DEPENDS="$(tr -d '\r\n' < "${metadata_dir}/nginx-abi-depends.txt")"

if [ -z "${NGINX_PACKAGE_VERSION}" ] || [ -z "${NGINX_SOURCE_VERSION}" ] || [ -z "${NGINX_ABI_DEPENDS}" ]; then
    echo "Failed to determine NGINX metadata for ${VERSION_CODENAME}" >&2
    exit 1
fi

echo "Detected NGINX package version for ${DISTRO}:${VERSION_CODENAME}: ${NGINX_PACKAGE_VERSION}"
echo "Using NGINX source version: ${NGINX_SOURCE_VERSION}"
echo "Using NGINX ABI dependency: ${NGINX_ABI_DEPENDS}"

cp "${SCRIPT_DIR}/scripts/postinst" "${DEBIAN_DIR}/postinst"
cp "${SCRIPT_DIR}/scripts/prerm" "${DEBIAN_DIR}/prerm"
cp "${SCRIPT_DIR}/scripts/postrm" "${DEBIAN_DIR}/postrm"
chmod 0755 "${DEBIAN_DIR}/postinst" "${DEBIAN_DIR}/prerm" "${DEBIAN_DIR}/postrm"

if [ -f "${CONFS_SOURCE_DIR}/${MODULE_CONF_NAME}" ]; then
    cp "${CONFS_SOURCE_DIR}/${MODULE_CONF_NAME}" "${MODULES_AVAILABLE_DIR}/${MODULE_CONF_NAME}"
else
    printf '%s\n' "${MODULE_CONF_CONTENT}" > "${MODULES_AVAILABLE_DIR}/${MODULE_CONF_NAME}"
fi
chmod 0644 "${MODULES_AVAILABLE_DIR}/${MODULE_CONF_NAME}"

curl -fsSL \
  "https://raw.githubusercontent.com/evanmiller/mod_zip/${MOD_ZIP_VERSION}/CHANGES" \
  -o "${DEBIAN_DIR}/changelog.Debian"
curl -fsSL \
  "https://raw.githubusercontent.com/evanmiller/mod_zip/${MOD_ZIP_VERSION}/LICENSE" \
  -o "${DOC_DIR}/LICENSE"
curl -fsSL \
  "https://raw.githubusercontent.com/evanmiller/mod_zip/${MOD_ZIP_VERSION}/README.markdown" \
  -o "${DOC_DIR}/README.markdown"
chmod 0644 "${DEBIAN_DIR}/changelog.Debian" "${DOC_DIR}/LICENSE" "${DOC_DIR}/README.markdown"

pushd "${STAGE_DIR}" >/dev/null
fpm \
  -s dir -t deb \
  --name "${PACKAGE_NAME}" \
  --license "${PACKAGE_LICENSE}" \
  --version "${PACKAGE_VERSION}" \
  --iteration "${ITERATION}~${VERSION_CODENAME}" \
  --architecture "${ARCH_DEB}" \
  --depends "${NGINX_ABI_DEPENDS}" \
  --depends "${LIBC_DEPENDS}" \
  --description "${DESCRIPTION}" \
  --url "${PACKAGE_URL}" \
  --maintainer "${MAINTAINER}" \
  --deb-changelog "debian/changelog.Debian" \
  --category httpd \
  --after-remove debian/postrm \
  --after-install debian/postinst \
  --before-remove debian/prerm \
  --package "${OUTPUT_DIR}/${PACKAGE_NAME}_${PACKAGE_VERSION}-${ITERATION}~${VERSION_CODENAME}_${ARCH_DEB}.deb" \
  usr/
popd >/dev/null
