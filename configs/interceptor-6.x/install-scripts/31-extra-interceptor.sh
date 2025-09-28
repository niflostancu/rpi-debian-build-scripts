#!/bin/bash
# Extra rootfs provisioning script for the Interceptor boards

set -eo pipefail
INTERCEPTOR_FILES="$INSTALL_SRC/files"

install -oroot -m644 "$INTERCEPTOR_FILES/network/eth0.network" "/etc/systemd/network/eth0.network"

# copy kernel-compiled (distributed) .dtbs to target's /boot (for persistence)
for DTS in "${KERNEL_COMPILE_DTS[@]}"; do
	DTB="${DTS%.dts}.dtb"
	cp -f "$KERNEL_DISTRIB_DIR/${DTB}" "/boot/$DTB"
done

mkdir -p "/etc/initramfs-tools/hooks/"
install -oroot -m755 "$INTERCEPTOR_FILES/initramfs-network-hook.sh" "/etc/initramfs-tools/hooks/interceptor-network"

