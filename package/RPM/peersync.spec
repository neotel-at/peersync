Summary: A simple file synchronisation tool based on rsync
Name: peersync
Version: %VERSION%
Release: 1
Group: System/Base
License: GPL
Vendor: NeoTel Telefonservice GmbH & Co KG
BuildArch: noarch
Requires: rsync, diffutils

%description
Peersync is a rsync based peer file synchronization tool

%install
mkdir -p $RPM_BUILD_ROOT/usr/bin
mkdir -p $RPM_BUILD_ROOT/etc

install -m 755 peersync.sh $RPM_BUILD_ROOT/usr/bin/peersync
install -m 640 etc/peersync.conf $RPM_BUILD_ROOT/etc/peersync.conf
install -m 640 etc/peersync.files $RPM_BUILD_ROOT/etc/peersync.files

%files
%defattr(-,root,root)
/usr/bin/peersync
%config(noreplace) /etc/peersync.conf
%config(noreplace) /etc/peersync.files

%post

