#!/bin/bash
# Installs base packages

apt_install locales tzdata
dpkg-reconfigure locales tzdata

apt_install apt-utils apt-transport-https git wget curl ssh rsync
apt_install systemd systemd-sysv systemd-resolved init udev gnupg net-tools ntp dosfstools
apt_install xz-utils file sudo gettext autoconf bsdutils less vim
apt_install isc-dhcp-client iputils-ping binutils kmod

if [[ -n "$EXTRA_PACKAGES" ]]; then
    apt_install "${EXTRA_PACKAGES[@]}"
fi

if [[ -n "$EXTRA_DEBS" ]]; then
(
    cd "$DIST_DIR"
    dpkg -i "${EXTRA_DEBS[@]}" || apt-get -f -y install
)
fi

