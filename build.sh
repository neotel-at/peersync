#!/bin/bash

TARGETDIR=dist
PEERSYNC_SCRIPT=peersync.sh
VERSION=`awk -F= '/^VERSION=/ { print $2 }' $PEERSYNC_SCRIPT`

if [ -z $VERSION ]; then
    echo "Failed to retrieve VERSION from peersync script"
    exit 1
fi

build_debian() {
  TARGET=$1
  BUILDDIR=/tmp/peersync.$$
  mkdir $BUILDDIR
  mkdir -p $BUILDDIR/usr/bin
  mkdir -p $BUILDDIR/etc

  cp -a package/DEBIAN $BUILDDIR/
  cp $PEERSYNC_SCRIPT $BUILDDIR/usr/bin/peersync
  cp etc/peersync.conf $BUILDDIR/etc/
  cp etc/peersync.files $BUILDDIR/etc/

  sed -i "s/%VERSION%/$VERSION/" $BUILDDIR/DEBIAN/control
  fakeroot dpkg-deb -v --build $BUILDDIR dist
}

if [ ! -d $TARGET ]; then
  mkdir dist
fi

echo "Building packages for version $VERSION of peersync"
build_debian $TARGETDIR

