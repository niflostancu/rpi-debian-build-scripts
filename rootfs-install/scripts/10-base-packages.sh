#!/bin/bash
# Installs base packages

apt_install locales tzdata
dpkg-reconfigure locales tzdata

apt_install apt-utils apt-transport-https git wget curl ssh rsync
apt_install systemd systemd-sysv systemd-resolved init udev gnupg net-tools ntp dosfstools
apt_install xz-utils file sudo gettext autoconf bsdutils less vim
apt_install isc-dhcp-client iputils-ping binutils kmod

apt_install unattended-upgrades apt-listchanges

