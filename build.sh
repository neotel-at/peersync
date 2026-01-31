#!/bin/bash
#
# For building peersync packages for Debian and RPM based systems 
# the script requires fakeroot and dpkg-deb for building deb packages
# and rpmbuild for building rpm packages
#
# Required packages:
#   Debian/Ubuntu: fakeroot dpkg-dev rpm
#   RHEL/CentOS:   rpm-build fakeroot dpkg-dev

TARGETDIR=dist
PEERSYNC_SCRIPT=peersync.sh
VERSION=`awk -F= '/^VERSION=/ { print $2 }' $PEERSYNC_SCRIPT`

if [ -z $VERSION ]; then
    echo "Failed to retrieve VERSION from peersync script"
    exit 1
fi

build_debian() {
  echo ""
  echo "#========================"
  echo "# Building Debian package"
  echo "#========================"
  BUILDDIR=/tmp/peersync.dpkg.$$
  mkdir $BUILDDIR
  mkdir -p $BUILDDIR/usr/bin
  mkdir -p $BUILDDIR/etc

  cp -a package/DEBIAN $BUILDDIR/
  cp $PEERSYNC_SCRIPT $BUILDDIR/usr/bin/peersync
  cp etc/peersync.conf $BUILDDIR/etc/
  cp etc/peersync.files $BUILDDIR/etc/
  chmod 640 $BUILDDIR/etc/peersync.*
  chmod 755 $BUILDDIR/usr/bin/peersync

  sed -i "s/%VERSION%/$VERSION/" $BUILDDIR/DEBIAN/control
  fakeroot dpkg-deb -v --build $BUILDDIR $TARGETDIR/peersync_$VERSION.deb
  rm -rf $BUILDDIR
}

build_rpm() {
  echo ""
  echo "#====================="
  echo "# Building RPM package"
  echo "#====================="
  BUILDSPEC=/tmp/peersync.$VERSION.spec
  sed "s/%VERSION%/$VERSION/" package/RPM/peersync.spec > $BUILDSPEC
  rpmbuild -v -ba --build-in-place $BUILDSPEC
  mv /home/rl/rpmbuild/RPMS/noarch/peersync-$VERSION-1.noarch.rpm $TARGETDIR/
  rm -f $BUILDSPEC
}

if [ ! -d $TARGETDIR ]; then
  mkdir $TARGETDIR
  if [ $? -ne 0 ]; then
      echo "Failed to create target directory $TARGETDIR"
      exit 1
  fi
fi

echo "Building packages for version $VERSION of peersync"
build_debian
build_rpm

