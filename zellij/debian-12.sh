#!/usr/bin/env bash
set -exo pipefail

ZELLIJ_VERSION=$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest | jq -r .tag_name | sed 's/^v//')
ARCHIVE="zellij-no-web-x86_64-unknown-linux-musl_${ZELLIJ_VERSION}.tar.gz"
URL="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-no-web-x86_64-unknown-linux-musl.tar.gz"

if [ ! -f "$ARCHIVE" ]; then
    wget -O "$ARCHIVE" "$URL"
fi

if [ ! -f zellij ]; then
    gzip -t "$ARCHIVE" && tar xf "$ARCHIVE"
fi

mkdir -p ../module_$(basename "$0")
mkdir -p ../fpm/deb/bookworm

chmod +x zellij
mv zellij ../fpm/zellij/bookworm/usr/bin/

pushd ../fpm/zellij/bookworm/ && \
fpm \
  -s dir -t deb \
  -p zellij_${ZELLIJ_VERSION}-1_bookworm_amd64.deb \
  --name zellij \
  --license MIT \
  --version ${ZELLIJ_VERSION}-1~bookworm \
  --architecture amd64 \
  --description "A terminal workspace with batteries included
 Zellij is a workspace aimed at developers, ops-oriented
 people and anyone who loves the terminal. Similar programs are sometimes called
 Terminal Multiplexers.
 .
 Zellij is designed around the philosophy that one must not sacrifice simplicity
 for power, taking pride in its great experience out of the box as well as the
 advanced features it places at its users' fingertips" \
  --maintainer "Aram Drevekenin <aram@poor.dev>" \
  --url "https://zellij.dev" \
  --deb-changelog "debian/changelog.Debian" \
  --category misc \
  --package ../../deb/bookworm/ \
  usr/&& \
popd 
