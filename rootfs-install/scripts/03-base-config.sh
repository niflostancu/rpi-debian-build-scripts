#!/bin/bash
# Base distribution configuration script

# Apt sources
cat <<EOF > /etc/apt/sources.list
deb $APT_REPO_BASE_URL $DEB_VERSION main
deb-src $APT_REPO_BASE_URL $DEB_VERSION main

deb $APT_REPO_SECURITY_URL $DEB_VERSION-security main
deb-src $APT_REPO_SECURITY_URL $DEB_VERSION-security main

deb $APT_REPO_BASE_URL $DEB_VERSION-updates main
deb-src $APT_REPO_BASE_URL $DEB_VERSION-updates main
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

