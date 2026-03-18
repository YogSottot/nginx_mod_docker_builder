#!/usr/bin/env bash
set -exo pipefail

: "${ITERATION:?ITERATION is required}"
: "${PACKAGE_NAME:?PACKAGE_NAME is required}"
: "${PACKAGE_LICENSE:?PACKAGE_LICENSE is required}"
: "${PACKAGE_URL:?PACKAGE_URL is required}"
: "${MAINTAINER:?MAINTAINER is required}"
: "${SUMMARY:?SUMMARY is required}"
: "${DESCRIPTION:?DESCRIPTION is required}"

ARCH_RPM="${ARCH_RPM:-x86_64}"
DIST_TAG="${DIST_TAG:-1}"
RPM_DIST_SUFFIX="${RPM_DIST_SUFFIX:-}"

ZELLIJ_VERSION="${ZELLIJ_VERSION:-$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest | jq -r .tag_name | sed 's/^v//')}"
ARCHIVE="zellij-no-web-x86_64-unknown-linux-musl_${ZELLIJ_VERSION}.tar.gz"
URL="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-no-web-x86_64-unknown-linux-musl.tar.gz"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${PROJECT_DIR}/.." && pwd)"

WORKDIR="${PROJECT_DIR}"
TOPDIR="${PROJECT_DIR}/rpmbuild/${DIST_TAG}"
SOURCES_DIR="${TOPDIR}/SOURCES"
SPECS_DIR="${TOPDIR}/SPECS"
OUTPUT_DIR="${REPO_ROOT}/rpm/${DIST_TAG}/${ARCH_RPM}"

if [ ! -f "${WORKDIR}/${ARCHIVE}" ]; then
    wget -O "${WORKDIR}/${ARCHIVE}" "$URL"
fi

if [ ! -f "${WORKDIR}/zellij" ]; then
    gzip -t "${WORKDIR}/${ARCHIVE}" && tar xf "${WORKDIR}/${ARCHIVE}" -C "${WORKDIR}"
fi

rm -rf "$TOPDIR"
mkdir -p "$SOURCES_DIR"
mkdir -p "$SPECS_DIR"
mkdir -p "$OUTPUT_DIR"

chmod +x "${WORKDIR}/zellij"
cp "${WORKDIR}/zellij" "${SOURCES_DIR}/${PACKAGE_NAME}"

wget -O "${SOURCES_DIR}/LICENSE" \
    https://raw.githubusercontent.com/zellij-org/zellij/refs/heads/main/LICENSE.md
wget -O "${SOURCES_DIR}/README.md" \
    https://raw.githubusercontent.com/zellij-org/zellij/refs/heads/main/README.md
wget -O "${SOURCES_DIR}/CHANGELOG" \
    "https://raw.githubusercontent.com/zellij-org/zellij/refs/tags/v${ZELLIJ_VERSION}/CHANGELOG.md"

CHANGELOG_DATE=$(
  awk -v ver="${ZELLIJ_VERSION}" '
    $0 ~ "^## \\[" ver "\\] - " {
      print $4
      exit
    }
  ' "${SOURCES_DIR}/CHANGELOG"
)

CHANGELOG_ENTRIES=$(
  awk -v ver="${ZELLIJ_VERSION}" '
    $0 ~ "^## \\[" ver "\\] - " { in_section=1; next }
    in_section && $0 ~ "^## \\[" { exit }
    in_section && $0 ~ /^\* / {
      sub(/^\* /, "- ")
      print
    }
  ' "${SOURCES_DIR}/CHANGELOG"
)

RPM_CHANGELOG_DATE=$(LC_ALL=C date -d "${CHANGELOG_DATE}" '+%a %b %d %Y')

"${WORKDIR}/zellij" setup --generate-completion bash > "${SOURCES_DIR}/${PACKAGE_NAME}.bash"
"${WORKDIR}/zellij" setup --generate-completion fish > "${SOURCES_DIR}/${PACKAGE_NAME}.fish"
"${WORKDIR}/zellij" setup --generate-completion zsh  > "${SOURCES_DIR}/_${PACKAGE_NAME}"

chmod 0644 "${SOURCES_DIR}/${PACKAGE_NAME}.bash"
chmod 0644 "${SOURCES_DIR}/${PACKAGE_NAME}.fish"
chmod 0644 "${SOURCES_DIR}/_${PACKAGE_NAME}"
chmod 0644 "${SOURCES_DIR}/LICENSE"
chmod 0644 "${SOURCES_DIR}/README.md"

pushd "$SPECS_DIR"
cat > "${PACKAGE_NAME}.spec" <<EOT
Name:           ${PACKAGE_NAME}
Version:        %{package_version}
Release:        %{package_iteration}%{?dist}
Summary:        ${SUMMARY}

License:        ${PACKAGE_LICENSE}
URL:            ${PACKAGE_URL}
BuildArch:      ${ARCH_RPM}

Source0:        ${PACKAGE_NAME}
Source1:        LICENSE
Source2:        README.md
Source3:        ${PACKAGE_NAME}.bash
Source4:        ${PACKAGE_NAME}.fish
Source5:        _${PACKAGE_NAME}

AutoReqProv:    no

%description
${DESCRIPTION}

%prep
# Nothing to prepare

%build
# Nothing to build

%install
install -Dpm0755 %{SOURCE0} %{buildroot}%{_bindir}/${PACKAGE_NAME}
install -Dpm0644 %{SOURCE1} %{buildroot}%{_docdir}/%{name}/LICENSE
install -Dpm0644 %{SOURCE2} %{buildroot}%{_docdir}/%{name}/README.md

install -Dpm0644 %{SOURCE3} %{buildroot}%{_datadir}/bash-completion/completions/${PACKAGE_NAME}
install -Dpm0644 %{SOURCE4} %{buildroot}%{_datadir}/fish/vendor_completions.d/${PACKAGE_NAME}.fish
install -Dpm0644 %{SOURCE5} %{buildroot}%{_datadir}/zsh/site-functions/_${PACKAGE_NAME}

%files
%license %{_docdir}/%{name}/LICENSE
%doc %{_docdir}/%{name}/README.md
%attr(0755,root,root) %{_bindir}/${PACKAGE_NAME}
%{_datadir}/bash-completion/completions/${PACKAGE_NAME}
%{_datadir}/fish/vendor_completions.d/${PACKAGE_NAME}.fish
%{_datadir}/zsh/site-functions/_${PACKAGE_NAME}

%changelog
* ${RPM_CHANGELOG_DATE} ${MAINTAINER} - %{package_version}-%{package_iteration}
${CHANGELOG_ENTRIES}
EOT
popd

pushd "$TOPDIR"
rpmbuild \
  --define "_topdir $(pwd)" \
  --define "package_version ${ZELLIJ_VERSION}" \
  --define "package_iteration ${ITERATION}" \
  -v -bb "./SPECS/${PACKAGE_NAME}.spec"
popd

find "${TOPDIR}/RPMS/${ARCH_RPM}" -maxdepth 1 -type f -name "*.rpm" -exec cp -f {} "${OUTPUT_DIR}/" \;
