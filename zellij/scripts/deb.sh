#!/usr/bin/env bash
set -exo pipefail

: "${DISTRO:?DISTRO is required}"
: "${VERSION_CODENAME:?VERSION_CODENAME is required}"
: "${ARCH_DEB:=amd64}"
: "${ITERATION:?ITERATION is required}"
: "${PACKAGE_NAME:?PACKAGE_NAME is required}"
: "${PACKAGE_LICENSE:?PACKAGE_LICENSE is required}"
: "${PACKAGE_URL:?PACKAGE_URL is required}"
: "${MAINTAINER:?MAINTAINER is required}"
: "${DESCRIPTION:?DESCRIPTION is required}"

ZELLIJ_VERSION="${ZELLIJ_VERSION:-$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest | jq -r .tag_name | sed 's/^v//')}"
ARCHIVE="zellij-no-web-x86_64-unknown-linux-musl_${ZELLIJ_VERSION}.tar.gz"
URL="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-no-web-x86_64-unknown-linux-musl.tar.gz"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${PROJECT_DIR}/.." && pwd)"

WORKDIR="${PROJECT_DIR}"
STAGE_DIR="${REPO_ROOT}/fpm/${PACKAGE_NAME}/${DISTRO}-${VERSION_CODENAME}"
OUTPUT_DIR="${REPO_ROOT}/deb/${VERSION_CODENAME}"

if [ ! -f "${WORKDIR}/${ARCHIVE}" ]; then
    wget -O "${WORKDIR}/${ARCHIVE}" "$URL"
fi

if [ ! -f "${WORKDIR}/zellij" ]; then
    gzip -t "${WORKDIR}/${ARCHIVE}" && tar xf "${WORKDIR}/${ARCHIVE}" -C "${WORKDIR}"
fi

mkdir -p "${OUTPUT_DIR}"

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/debian"
mkdir -p "$STAGE_DIR/usr/bin"
mkdir -p "$STAGE_DIR/usr/share/bash-completion/completions"
mkdir -p "$STAGE_DIR/usr/share/fish/vendor_completions.d"
mkdir -p "$STAGE_DIR/usr/share/zsh/vendor-completions"
mkdir -p "$STAGE_DIR/usr/share/doc/${PACKAGE_NAME}"

chmod +x "${WORKDIR}/zellij"
cp "${WORKDIR}/zellij" "$STAGE_DIR/usr/bin/${PACKAGE_NAME}"

wget -O "$STAGE_DIR/debian/changelog.Debian" \
    "https://raw.githubusercontent.com/zellij-org/zellij/refs/tags/v${ZELLIJ_VERSION}/CHANGELOG.md"
wget -O "$STAGE_DIR/usr/share/doc/${PACKAGE_NAME}/LICENSE" \
    "https://raw.githubusercontent.com/zellij-org/zellij/refs/tags/v${ZELLIJ_VERSION}/LICENSE.md"
wget -O "$STAGE_DIR/usr/share/doc/${PACKAGE_NAME}/README.md" \
    "https://raw.githubusercontent.com/zellij-org/zellij/refs/tags/v${ZELLIJ_VERSION}/README.md"

"$STAGE_DIR/usr/bin/${PACKAGE_NAME}" setup --generate-completion bash \
    > "$STAGE_DIR/usr/share/bash-completion/completions/${PACKAGE_NAME}"
"$STAGE_DIR/usr/bin/${PACKAGE_NAME}" setup --generate-completion fish \
    > "$STAGE_DIR/usr/share/fish/vendor_completions.d/${PACKAGE_NAME}.fish"
"$STAGE_DIR/usr/bin/${PACKAGE_NAME}" setup --generate-completion zsh \
    > "$STAGE_DIR/usr/share/zsh/vendor-completions/_${PACKAGE_NAME}"

chmod 0644 "$STAGE_DIR/usr/share/bash-completion/completions/${PACKAGE_NAME}"
chmod 0644 "$STAGE_DIR/usr/share/fish/vendor_completions.d/${PACKAGE_NAME}.fish"
chmod 0644 "$STAGE_DIR/usr/share/zsh/vendor-completions/_${PACKAGE_NAME}"
chmod 0644 "$STAGE_DIR/usr/share/doc/${PACKAGE_NAME}/LICENSE"
chmod 0644 "$STAGE_DIR/usr/share/doc/${PACKAGE_NAME}/README.md"

pushd "$STAGE_DIR"
fpm \
  -s dir -t deb \
  --name "${PACKAGE_NAME}" \
  --license "${PACKAGE_LICENSE}" \
  --version "${ZELLIJ_VERSION}" \
  --iteration "${ITERATION}~${VERSION_CODENAME}" \
  --architecture "${ARCH_DEB}" \
  --description "${DESCRIPTION}" \
  --maintainer "${MAINTAINER}" \
  --url "${PACKAGE_URL}" \
  --deb-changelog "debian/changelog.Debian" \
  --category misc \
  --package "${OUTPUT_DIR}/${PACKAGE_NAME}_${ZELLIJ_VERSION}-${ITERATION}~${VERSION_CODENAME}_${ARCH_DEB}.deb" \
  usr/
popd

