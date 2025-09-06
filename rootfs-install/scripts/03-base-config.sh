#!/bin/bash
# Base distribution configuration script

. /etc/os-release

# Apt sources
cat <<EOF > /etc/apt/sources.list
deb $APT_REPO_BASE_URL $VERSION_CODENAME main contrib non-free non-free-firmware
deb-src $APT_REPO_BASE_URL $VERSION_CODENAME main contrib non-free non-free-firmware

deb $APT_REPO_SECURITY_URL $VERSION_CODENAME-security main contrib non-free non-free-firmware
deb-src $APT_REPO_SECURITY_URL $VERSION_CODENAME-security main contrib non-free non-free-firmware

deb $APT_REPO_BASE_URL $VERSION_CODENAME-updates main contrib non-free non-free-firmware
deb-src $APT_REPO_BASE_URL $VERSION_CODENAME-updates main contrib non-free non-free-firmware
EOF

# Disable the auto installation of recommended packages
cat <<EOF > /etc/apt/apt.conf.d/99-no-recommends
APT::Install-Recommends "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";
EOF

# we need to install those ASAP
apt_update
apt_install debconf-utils debconf

cat <<EOF > /etc/dpkg/.preseed-conf
tzdata tzdata/Areas select $TIMEZONE_AREA
tzdata tzdata/Zones/$TIMEZONE_AREA select $TIMEZONE_CITY

locales locales/locales_to_be_generated multiselect     en_US.UTF-8 UTF-8
locales locales/default_environment_locale      select  en_US.UTF-8
EOF

debconf-set-selections "/etc/dpkg/.preseed-conf"

