#!/usr/bin/env bash
set -exo pipefail

mkdir -p ../module_$(basename "$0")
mkdir -p ../fpm/deb/bookworm

pushd ../fpm/mod_auth_ntlm_winbind/bookworm/ && \
fpm \
  -s dir -t deb \
  -p libapache2-mod-auth-ntlm-winbind_0.0.0-0_bookworm_amd64.deb \
  --name libapache2-mod-auth-ntlm-winbind \
  --license Apache-2.0 \
  --version 0.0.0-0~bookworm \
  --architecture amd64 \
  --depends "apache2-api-20120211, libc6 (>= 2.14), winbind, libnss-winbind, libpam-winbind, krb5-user" \
  --description "apache2 module for NTLM authentication against Winbind 
The mod_auth_ntlm_winbind module provides authentication and 
authorisation over the web against a Microsoft Windows NT/2000/XP/etc or 
Samba Domain Controller using Samba's winbind daemon running on the 
same machine Apache is running on.
.
If you're considering using this module, you should be aware that NTLM
isn't regarded as very secure by modern standards - even Microsoft no longer
recommends its use - and where possible, you probably want to use gssapi with
negotiate auth over https instead (see Debian package
libapache2-mod-auth-gssapi)." \
  --maintainer "Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>" \
  --url "http://adldap.sourceforge.net/wiki/doku.php?id=mod_auth_ntlm_winbind" \
  --deb-changelog "debian/changelog.Debian" \
  --category web \
  --config-files etc/apache2/mods-available/auth_ntlm_winbind.load \
  --after-remove debian/postrm \
  --after-install debian/postinst \
  --before-remove debian/prerm \
  --package ../../deb/bookworm/ \
  usr/&& \
popd 

