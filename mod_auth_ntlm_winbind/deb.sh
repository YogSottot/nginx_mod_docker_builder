#!/usr/bin/env bash
set -euo pipefail

: "${TARGET:?TARGET is required}"
: "${PACKAGE_NAME:?PACKAGE_NAME is required}"
: "${PACKAGE_LICENSE:?PACKAGE_LICENSE is required}"
: "${PACKAGE_URL:?PACKAGE_URL is required}"
: "${MAINTAINER:?MAINTAINER is required}"
: "${ARCH_DEB:?ARCH_DEB is required}"
: "${BASE_IMAGE:?BASE_IMAGE is required}"
: "${DOCKER_IMAGE:?DOCKER_IMAGE is required}"
: "${SOURCE_ROOT:?SOURCE_ROOT is required}"
: "${SOURCE_DIR:?SOURCE_DIR is required}"
: "${MODULE_NAME:?MODULE_NAME is required}"
: "${BUILD_DEPS:?BUILD_DEPS is required}"
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
DOC_DIR="${STAGE_DIR}/usr/share/doc/${PACKAGE_NAME}"
MODULES_DIR="${STAGE_DIR}/usr/lib/apache2/modules"
DEBIAN_DIR="${STAGE_DIR}/debian"
BUILD_IMAGE="${DOCKER_IMAGE}:${VERSION_CODENAME}"
BUILD_OUTPUT_DIR="/opt/mod_auth_ntlm_winbind"
BUILD_METADATA_DIR="/usr/share/tmp"
PACKAGE_OUTPUT="${OUTPUT_DIR}/${PACKAGE_NAME}_${PACKAGE_VERSION}-${ITERATION}~${VERSION_CODENAME}_${ARCH_DEB}.deb"
declare -A SEEN_DEPENDS=()

trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "${value}"
}

append_dependency_arg() {
    local target_name="$1"
    local -n target_ref="${target_name}"
    local dependency

    dependency="$(trim "${2}")"
    if [ -z "${dependency}" ] || [ -n "${SEEN_DEPENDS[${dependency}]:-}" ]; then
        return
    fi

    SEEN_DEPENDS["${dependency}"]=1
    target_ref+=(--depends "${dependency}")
}

append_dependency_args() {
    local target_name="$1"
    local raw_dependencies="$2"
    local dependency=""
    local token
    local in_constraint=0

    if [[ "${raw_dependencies}" == *","* ]]; then
        while IFS= read -r token; do
            append_dependency_arg "${target_name}" "${token}"
        done < <(printf '%s' "${raw_dependencies}" | tr ',' '\n')
        return
    fi

    for token in ${raw_dependencies}; do
        if [ -z "${dependency}" ]; then
            dependency="${token}"
            continue
        fi

        if [ "${in_constraint}" -eq 1 ]; then
            dependency+=" ${token}"
            if [[ "${token}" == *")" ]]; then
                in_constraint=0
            fi
            continue
        fi

        if [[ "${token}" == \(* ]]; then
            dependency+=" ${token}"
            if [[ "${token}" != *")" ]]; then
                in_constraint=1
            fi
            continue
        fi

        append_dependency_arg "${target_name}" "${dependency}"
        dependency="${token}"
    done

    append_dependency_arg "${target_name}" "${dependency}"
}

for required_path in \
    "${ASSETS_DIR}/debian/changelog.Debian" \
    "${ASSETS_DIR}/debian/postinst" \
    "${ASSETS_DIR}/debian/prerm" \
    "${ASSETS_DIR}/debian/postrm" \
    "${ASSETS_DIR}/etc/apache2/mods-available/auth_ntlm_winbind.load" \
    "${ASSETS_DIR}/usr/share/doc/${PACKAGE_NAME}/README" \
    "${ASSETS_DIR}/usr/share/doc/${PACKAGE_NAME}/copyright"; do
    if [ ! -f "${required_path}" ]; then
        echo "Missing required asset: ${required_path}" >&2
        exit 1
    fi
done

rm -rf "${STAGE_DIR}"
mkdir -p "${OUTPUT_DIR}" "${DOC_DIR}" "${MODULES_DIR}" "${DEBIAN_DIR}"
rsync -a --exclude 'usr/lib/apache2/modules/mod_auth_ntlm_winbind.so' "${ASSETS_DIR}/" "${STAGE_DIR}"

docker build \
    --tag "${BUILD_IMAGE}" \
    --file "${SCRIPT_DIR}/Dockerfile" \
    --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
    --build-arg "MAINTAINER=${MAINTAINER}" \
    --build-arg "BUILD_DEPS=${BUILD_DEPS}" \
    --build-arg "SOURCE_ROOT=${SOURCE_ROOT}" \
    --build-arg "SOURCE_DIR=${SOURCE_DIR}" \
    --build-arg "MODULE_NAME=${MODULE_NAME}" \
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

docker cp "${container_id}:${BUILD_OUTPUT_DIR}/usr/lib/apache2/modules/${MODULE_NAME}" "${MODULES_DIR}/${MODULE_NAME}"
docker cp "${container_id}:${BUILD_METADATA_DIR}/apache-version.txt" "${metadata_dir}/apache-version.txt"
docker cp "${container_id}:${BUILD_METADATA_DIR}/apache-api-depends.txt" "${metadata_dir}/apache-api-depends.txt"

APACHE_VERSION="$(tr -d '\r\n' < "${metadata_dir}/apache-version.txt")"
APACHE_API_DEPENDS="$(tr -d '\r\n' < "${metadata_dir}/apache-api-depends.txt")"

if [ -z "${APACHE_VERSION}" ] || [ -z "${APACHE_API_DEPENDS}" ]; then
    echo "Failed to determine Apache metadata for ${VERSION_CODENAME}" >&2
    exit 1
fi

echo "Detected Apache package version for ${DISTRO}:${VERSION_CODENAME}: ${APACHE_VERSION}"
echo "Using Apache ABI dependency: ${APACHE_API_DEPENDS}"

chmod 0755 "${DEBIAN_DIR}/postinst" "${DEBIAN_DIR}/prerm" "${DEBIAN_DIR}/postrm"
chmod 0644 \
    "${STAGE_DIR}/etc/apache2/mods-available/auth_ntlm_winbind.load" \
    "${MODULES_DIR}/${MODULE_NAME}" \
    "${DOC_DIR}/README" \
    "${DOC_DIR}/copyright" \
    "${DEBIAN_DIR}/changelog.Debian"

rm -f "${PACKAGE_OUTPUT}"

fpm_args=(
    -s dir -t deb
    --name "${PACKAGE_NAME}"
    --license "${PACKAGE_LICENSE}"
    --version "${PACKAGE_VERSION}"
    --iteration "${ITERATION}~${VERSION_CODENAME}"
    --architecture "${ARCH_DEB}"
    --description "${DESCRIPTION}"
    --maintainer "${MAINTAINER}"
    --url "${PACKAGE_URL}"
    --deb-changelog "debian/changelog.Debian"
    --category web
    --config-files "${CONFIG_FILE}"
    --after-remove debian/postrm
    --after-install debian/postinst
    --before-remove debian/prerm
    --package "${PACKAGE_OUTPUT}"
)

append_dependency_arg fpm_args "${APACHE_API_DEPENDS}"
append_dependency_args fpm_args "${DEPENDS}"

pushd "${STAGE_DIR}" >/dev/null
fpm \
    "${fpm_args[@]}" \
    etc/ \
    usr/
popd >/dev/null
