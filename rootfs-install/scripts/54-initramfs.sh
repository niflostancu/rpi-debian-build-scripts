#!/bin/bash
# Installs initramfs

INITRAMFS_SCRIPT="/etc/initramfs/post-update.d/90-rpi-boot-img"

if [[ "$SKIP_INITRAMFS" =~ ^1|y(es)?$ ]]; then
    rm -f "$INITRAMFS_SCRIPT"
fi

_INITRAMFS_PACKAGES=(initramfs-tools console-setup)
if [[ "$INITRAMFS_CRYPTROOT" =~ ^1|y(es)?$ ]]; then
    _INITRAMFS_PACKAGES+=(cryptsetup cryptsetup-initramfs)
fi
if [[ "$INITRAMFS_DROPBEAR" =~ ^1|y(es)?$ ]]; then
    _INITRAMFS_PACKAGES+=(dropbear-initramfs)
fi
apt_install "${_INITRAMFS_PACKAGES[@]}"

if [[ "$INITRAMFS_DROPBEAR" =~ ^1|y(es)?$ ]]; then
    # dropbear-initramfs customization
    [[ -n "$DROPBEAR_AUTHORIZED_KEYS" ]] || \
        DROPBEAR_AUTHORIZED_KEYS="$DIST_DIR/authorized_keys"
    if [[ -n "$DROPBEAR_AUTHORIZED_KEYS" && -f "$DROPBEAR_AUTHORIZED_KEYS" ]]; then
        mkdir -p /etc/dropbear/initramfs
        install -oroot -m755 "$DROPBEAR_AUTHORIZED_KEYS" "/etc/dropbear/initramfs/authorized_keys"
    fi
    if [[ -n "$DROPBEAR_PORT" ]]; then
        sed -i 's/^#\?DROPBEAR_OPTIONS=.*/DROPBEAR_OPTIONS="-p '$DROPBEAR_PORT'"/' \
            /etc/dropbear/initramfs/dropbear.conf
    fi
fi

# install initramfs generation hooks to generate boot.img
# https://kernel-team.pages.debian.net/kernel-handbook/ch-update-hooks.html
INITRAMFS_SRC_SCRIPT="$INSTALL_SRC/files/initramfs/rpi-post-update-hook"
install -oroot -m755 -d "$(dirname "$INITRAMFS_SCRIPT")"
install -oroot -m755 "$INITRAMFS_SRC_SCRIPT" "$INITRAMFS_SCRIPT"

