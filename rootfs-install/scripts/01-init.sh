#!/bin/bash
# Provisioning script initialization: common variables

APT_REPO_BASE_URL="http://deb.debian.org/debian"
APT_REPO_SECURITY_URL="http://deb.debian.org/debian-security/"

TIMEZONE_AREA=${TIMEZONE_AREA:-Europe}
TIMEZONE_CITY=${TIMEZONE_AREA:-Bucharest}

MAIN_USER=${MAIN_USER:-pi}

# fix path from chroot / systemd-nspawn
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games

# copy utility scripts library to a persisent location
RPI_DEB_LIB_DIR=/usr/local/lib/rpi-debian
install -oroot -m755 -d "$RPI_DEB_LIB_DIR"
install -oroot -m755 "$SRC_DIR/lib/fetch.sh" "$SRC_DIR/lib/base.sh" \
    "$RPI_DEB_LIB_DIR"

