#!/bin/bash
# Interceptor files install script
set -eo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"

install -oroot -m755 "$SRC_DIR/config-rtl8367rb.sh" "/usr/local/bin/config-rtl8367rb.sh"
install -oroot -m644 "$SRC_DIR/udev-interceptor.rules" "/etc/udev/rules.d/90-interceptor.rules"
install -oroot -m644 "$SRC_DIR/20-wan.network" "/etc/systemd/network/20-wan.network"
cp "$SRC_DIR/interceptor.dtb" "/boot/interceptor.dtb"

install -oroot -m755 "$SRC_DIR/initramfs-network-hook.sh" "/etc/initramfs-tools/hooks/interceptor-network"

systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl disable systemd-networkd-wait-online.service

