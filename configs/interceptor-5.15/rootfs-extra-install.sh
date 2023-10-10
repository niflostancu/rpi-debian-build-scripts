#!/bin/bash
# Extra rootfs provisioning script for the Interceptor boards

set -eo pipefail
INTERCEPTOR_FILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)/files"

install -oroot -m755 "$INTERCEPTOR_FILES/config-rtl8367rb.sh" "/usr/local/bin/config-rtl8367rb.sh"
install -oroot -m644 "$INTERCEPTOR_FILES/udev-interceptor.rules" "/etc/udev/rules.d/90-interceptor.rules"
install -oroot -m644 "$INTERCEPTOR_FILES/eth0.network" "/etc/systemd/network/eth0.network"
install -oroot -m644 "$INTERCEPTOR_FILES/eth0-wan.network" "/etc/systemd/network/eth0-wan.network"

cp -f "$INTERCEPTOR_FILES/../kernel-5.15/interceptor.dtb" "/boot/interceptor-rpi-cm4-5.15.dtb"
cp -f "$INTERCEPTOR_FILES/$SWCONFIG_DEB" "$DIST_DIR/$SWCONFIG_DEB"

mkdir -p "/etc/initramfs-tools/hooks/"
install -oroot -m755 "$INTERCEPTOR_FILES/initramfs-network-hook.sh" "/etc/initramfs-tools/hooks/interceptor-network"

