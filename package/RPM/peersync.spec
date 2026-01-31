Summary: A simple file synchronisation tool based on rsync
Name: peersync
Version: %VERSION%
Release: 1
Group: System/Base
License: GPL
Vendor: NeoTel Telefonservice GmbH & Co KG
# Source: %{name}.tar.gz
BuildArch: noarch
BuildRoot: /var/tmp/%{name}-buildroot
Requires: rsync, diffutils

%description
Peersync is a rsync based peer file synchronization tool

# %prep
# %setup -q

%build
# env

%install
# mkdir -p $RPM_BUILD_ROOT/usr/bin
# mkdir -p $RPM_BUILD_ROOT/etc

# install -m 755 peersync.sh $RPM_BUILD_ROOT/usr/bin/peersync
# install -m 755 etc/peersync.conf $RPM_BUILD_ROOT/etc/peersync.conf
# install -m 755 etc/peersync.files $RPM_BUILD_ROOT/etc/peersync.files

%clean
# if( [ $RPM_BUILD_ROOT != '/' ] ); then rm -rf $RPM_BUILD_ROOT; fi;

%files
%defattr(-,root,root)
/usr/bin/peersync
%config(noreplace)
/etc/peersync.conf
/etc/peersync.files

%post

