#!/bin/sh
set -eo pipefail
shopt -s inherit_errexit

cd `dirname $0`

export PROJECT=gnustep-base
export GITHUB_REPO=gnustep/libs-base
export TAG=

# load environment and prepare project
../scripts/common.bat prepare_project

cd "$SRCROOT/$PROJECT"

echo
echo "### Loading GNUstep environment"
. "$UNIX_INSTALL_PREFIX/share/GNUstep/Makefiles/GNUstep.sh"

# VCPKG - TODO: use target triple
VCPKG_BINDIR=`cygpath $VCPKG_ROOT`/installed/x64-windows/bin
VCPKG_LIBDIR=`cygpath $VCPKG_ROOT`/installed/x64-windows/lib
VCPKG_INCDIR=`cygpath $VCPKG_ROOT`/installed/x64-windows/include

# VCPKG - configure script needs help (finding DLLs)
export PATH=$PATH:$VCPKG_BINDIR

# VCPKG - configure script needs help (finding pkg-config info)
export PKG_CONFIG_LIBDIR=$VCPKG_LIBDIR/pkgconfig

echo
echo "### Running autoconf"
WANT_AUTOCONF="2.69" autoreconf -fvi

echo
echo "### Running configure"
./configure \
  --host=$TARGET \
  --disable-tls \
  $GNUSTEP_BASE_OPTIONS

echo
echo "### Building"
make -j`nproc`

echo
echo "### Installing"
make install
