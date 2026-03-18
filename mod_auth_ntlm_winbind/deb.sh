#!/usr/bin/env bash
set -euo pipefail

: "${TARGET:?TARGET is required}"
: "${PACKAGE_NAME:?PACKAGE_NAME is required}"
: "${PACKAGE_LICENSE:?PACKAGE_LICENSE is required}"
: "${PACKAGE_URL:?PACKAGE_URL is required}"
: "${MAINTAINER:?MAINTAINER is required}"
: "${ARCH_DEB:?ARCH_DEB is required}"
: "${PACKAGE_VERSION:?PACKAGE_VERSION is required}"
: "${ITERATION:?ITERATION is required}"
: "${DESCRIPTION:?DESCRIPTION is required}"
: "${DEPENDS:?DEPENDS is required}"
: "${CONFIG_FILE:?CONFIG_FILE is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

for suffix in DISTRO VERSION_CODENAME; do
    var_name="${TARGET}_${suffix}"
    value="${!var_name:-}"
    if [ -z "${value}" ]; then
        echo "Missing required variable: ${var_name}" >&2
        exit 1
    fi
    export "${suffix}=${value}"
done

ASSETS_DIR="${SCRIPT_DIR}/assets"
STAGE_DIR="${REPO_ROOT}/fpm/${PACKAGE_NAME}/${VERSION_CODENAME}"
OUTPUT_DIR="${REPO_ROOT}/deb/${VERSION_CODENAME}"

for required_path in \
    "${ASSETS_DIR}/debian/changelog.Debian" \
    "${ASSETS_DIR}/debian/postinst" \
    "${ASSETS_DIR}/debian/prerm" \
    "${ASSETS_DIR}/debian/postrm" \
    "${ASSETS_DIR}/etc/apache2/mods-available/auth_ntlm_winbind.load" \
    "${ASSETS_DIR}/usr/lib/apache2/modules/mod_auth_ntlm_winbind.so" \
    "${ASSETS_DIR}/usr/share/doc/${PACKAGE_NAME}/README" \
    "${ASSETS_DIR}/usr/share/doc/${PACKAGE_NAME}/copyright"; do
    if [ ! -f "${required_path}" ]; then
        echo "Missing required asset: ${required_path}" >&2
        exit 1
    fi
done

rm -rf "${STAGE_DIR}"
mkdir -p "${OUTPUT_DIR}" "${STAGE_DIR}"
rsync -a "${ASSETS_DIR}/" "${STAGE_DIR}"
chmod 0755 "${STAGE_DIR}/debian/postinst" "${STAGE_DIR}/debian/prerm" "${STAGE_DIR}/debian/postrm"
chmod 0644 \
    "${STAGE_DIR}/etc/apache2/mods-available/auth_ntlm_winbind.load" \
    "${STAGE_DIR}/usr/lib/apache2/modules/mod_auth_ntlm_winbind.so" \
    "${STAGE_DIR}/usr/share/doc/${PACKAGE_NAME}/README" \
    "${STAGE_DIR}/usr/share/doc/${PACKAGE_NAME}/copyright" \
    "${STAGE_DIR}/debian/changelog.Debian"

pushd "${STAGE_DIR}" >/dev/null
fpm \
    -s dir -t deb \
    --name "${PACKAGE_NAME}" \
    --license "${PACKAGE_LICENSE}" \
    --version "${PACKAGE_VERSION}" \
    --iteration "${ITERATION}~${VERSION_CODENAME}" \
    --architecture "${ARCH_DEB}" \
    --depends "${DEPENDS}" \
    --description "${DESCRIPTION}" \
    --maintainer "${MAINTAINER}" \
    --url "${PACKAGE_URL}" \
    --deb-changelog "debian/changelog.Debian" \
    --category web \
    --config-files "${CONFIG_FILE}" \
    --after-remove debian/postrm \
    --after-install debian/postinst \
    --before-remove debian/prerm \
    --package "${OUTPUT_DIR}/${PACKAGE_NAME}_${PACKAGE_VERSION}-${ITERATION}~${VERSION_CODENAME}_${ARCH_DEB}.deb" \
    etc/ \
    usr/
popd >/dev/null
