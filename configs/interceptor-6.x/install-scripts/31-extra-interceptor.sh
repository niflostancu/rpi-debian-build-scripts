#!/bin/bash
# Extra rootfs provisioning script for the Interceptor boards

set -eo pipefail
INTERCEPTOR_FILES="$INSTALL_SRC/files"

install -oroot -m644 "$INTERCEPTOR_FILES/network/eth0.network" "/etc/systemd/network/eth0.network"

cp -f "$INTERCEPTOR_DTB_FROM" "/boot/$INTERCEPTOR_DTB_NAME"

mkdir -p "/etc/initramfs-tools/hooks/"
install -oroot -m755 "$INTERCEPTOR_FILES/initramfs-network-hook.sh" "/etc/initramfs-tools/hooks/interceptor-network"

