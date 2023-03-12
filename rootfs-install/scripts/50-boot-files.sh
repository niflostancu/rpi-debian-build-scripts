#!/bin/bash
# Installs bootloader / kernel files & configs

apt_install initramfs-tools dropbear-initramfs cryptsetup

# debs to install
KERNEL_PREFIXES=(linux-image- linux-headers- linux-libc-dev)

KERNEL_FILE="$(shopt -s nullglob; cd "$DIST_DIR/"; files=( "${KERNEL_PREFIXES[0]}"*.deb ); echo "$files")"
if [[ -z "$KERNEL_FILE" || ! -f "$DIST_DIR/$KERNEL_FILE" ]]; then
    log_error "Unable to find kernel .debs inside $DIST_DIR!"
    return 0
fi

(
    cd "$DIST_DIR/"
    KERNEL_FILES=()
    for prefix in "${KERNEL_PREFIXES[@]}"; do
        KERNEL_FILES+=( "$prefix"*.deb )
    done
    log_debug dpkg -i "${KERNEL_FILES[@]}"
    dpkg -i "${KERNEL_FILES[@]}"
)


