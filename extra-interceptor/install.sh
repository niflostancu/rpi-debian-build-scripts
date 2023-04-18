#!/bin/bash
# Interceptor files install script
set -eo pipefail
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"

install -oroot -m755 "$SRC_DIR/config-rtl8367rb.sh" "/usr/local/bin/config-rtl8367rb.sh"
install -oroot -m644 "$SRC_DIR/udev-interceptor.rules" "/etc/udev/rules.d/90-interceptor.rules"
install -oroot -m644 "$SRC_DIR/eth0.network" "/etc/systemd/network/eth0.network"
install -oroot -m644 "$SRC_DIR/eth0-wan.network" "/etc/systemd/network/eth0-wan.network"
cp "$SRC_DIR/interceptor.dtb" "/boot/interceptor.dtb"

install -oroot -m755 "$SRC_DIR/initramfs-network-hook.sh" "/etc/initramfs-tools/hooks/interceptor-network"

