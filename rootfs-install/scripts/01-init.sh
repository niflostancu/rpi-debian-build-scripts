#!/bin/bash
# Provisioning script initialization: common variables

APT_REPO_BASE_URL="http://deb.debian.org/debian"
APT_REPO_SECURITY_URL="http://deb.debian.org/debian-security/"
DEB_ARCH="arm64"
DEB_VERSION="bullseye"

TIMEZONE_AREA=${TIMEZONE_AREA:-Europe}
TIMEZONE_CITY=${TIMEZONE_AREA:-Bucharest}

MAIN_USER=${MAIN_USER:-pi}

# fix path from chroot / systemd-nspawn
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

