#!/usr/bin/env python
"""Use the SRPM's current nginx/modules build recipe on EL7."""
from __future__ import print_function
import re
import sys

path, openssl_version, build_debug, push_stream_version = sys.argv[1:]
if build_debug not in ('0', '1'):
    sys.exit('BUILD_DEBUG must be 0 or 1')
with open(path) as stream:
    spec = stream.read()
# Keep the original branches in the spec, but activate the current EL9 recipe
# on EL7 instead of the obsolete EL7 recipe (which references absent sources).
spec, count = re.subn(r'^%define rhel 9$', '%define rhel 7', spec, flags=re.M)
if count != 1:
    sys.exit('Unexpected spec: missing rhel 9 definition')
spec = re.sub(r'^(%if 0%\{\?rhel\} == )7$', r'\g<1>99', spec, flags=re.M)
spec = re.sub(r'^(%if 0%\{\?rhel\} == )9$', r'\g<1>7', spec, flags=re.M)
spec = re.sub(r'^%define build_debug [01]$', '%define build_debug ' + build_debug, spec, flags=re.M)
spec = spec.replace('openssl >= 3.5.0', 'openssl >= 1.0.1')
spec = spec.replace('openssl-devel >= 3.5.0', 'openssl-devel >= 1.0.1')
spec = spec.replace('openssl-3.5.9', 'openssl-' + openssl_version)
# HTTP/3 requires the newer OpenSSL recipe; retain HTTP/2 with OpenSSL 1.1.1.
spec = re.sub(r'^.*--with-http_v3_module.*\n', '', spec, flags=re.M)
# The standalone CMake is installed under /opt, outside the RPM database.
spec = re.sub(r'^BuildRequires:\s*cmake\s*$', '', spec, flags=re.M)
# GCC 4.8 does not understand newer ISA levels such as x86-64-v2.
# Use the baseline x86_64 ISA and avoid tuning for the build machine.
spec = re.sub(r'-march=[A-Za-z0-9_-]+', '-march=x86-64', spec)
spec = re.sub(r'-mtune=[A-Za-z0-9_-]+', '-mtune=generic', spec)
# GCC 4.8 defaults to GNU89; the current Brotli sources require C99.
spec = spec.replace('-DCMAKE_C_FLAGS="', '-DCMAKE_C_FLAGS="-std=gnu99 ')
# The EL9 SRPM does not include push-stream. Add its source and enable it
# in both the normal and debug builds of the current recipe.
push_stream = 'nginx-push-stream-module-' + push_stream_version
spec = spec.replace('Source11:', 'Source10:\t' + push_stream + '.tgz\nSource11:', 1)
spec = spec.replace('%setup -q', '%setup -q\n%{__tar} zxvf %{SOURCE10}', 1)
module_line = '        --add-module=%{_builddir}/%{name}-%{version}/%{mod_zip}'
spec = spec.replace(module_line, '        --add-module=%{_builddir}/%{name}-%{version}/' + push_stream + ' \\\n' + module_line)
with open(path, 'w') as stream:
    stream.write(spec)
