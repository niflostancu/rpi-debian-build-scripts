#!/bin/bash
# Installs bootloader / kernel files & configs

apt_install initramfs-tools dropbear-initramfs cryptsetup raspi-firmware

# debs to install
KERNEL_PREFIXES=(linux-image- linux-headers- linux-libc-dev)

KERNEL_FILE="$(shopt -s nullglob; cd "$DIST_DIR/"; files=( "${KERNEL_PREFIXES[0]}"*.deb ); echo "$files")"
if [[ -z "$KERNEL_FILE" || ! -f "$DIST_DIR/$KERNEL_FILE" ]]; then
    log_error "Unable to find kernel .debs inside $DIST_DIR!"
    return 0
fi

# first, install initramfs generation hooks to generate boot.img
# https://kernel-team.pages.debian.net/kernel-handbook/ch-update-hooks.html
install -oroot -m755 -d /etc/initramfs/post-update.d/
install -oroot -m755 "$ROOTFS_INSTALL_SRC/files/initramfs-post-update/rpi-boot-img" \
    /etc/initramfs/post-update.d/90-rpi-boot-img
# save configuration vars
cat << EOF > /etc/initramfs/rpi-vars.sh
$([[ -z "$RPI_CMDLINE" ]] || declare -p RPI_CMDLINE)
$([[ -z "$RPI_FIRMWARE_FILES" ]] || declare -p RPI_FIRMWARE_FILES)
$([[ -z "$RPI_CONFIG" ]] || declare -p RPI_CONFIG)

EOF

# [Re]Install kernel package (initramfs will be generated and hooks run)
(
    cd "$DIST_DIR/"
    KERNEL_FILES=()
    for prefix in "${KERNEL_PREFIXES[@]}"; do
        KERNEL_FILES+=( "$prefix"*.deb )
    done
    log_debug dpkg -i "${KERNEL_FILES[@]}"
    dpkg -i "${KERNEL_FILES[@]}"
)

