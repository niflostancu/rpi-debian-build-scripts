#!/bin/bash
# Installs bootloader / kernel files & configs

apt_install initramfs-tools cryptsetup console-setup dropbear-initramfs \
    cryptsetup-initramfs raspi-firmware

# boot-related configuration files
[[ -n "$DROPBEAR_AUTHORIZED_KEYS" ]] || \
    DROPBEAR_AUTHORIZED_KEYS="$DIST_DIR/authorized_keys"
if [[ -n "$DROPBEAR_AUTHORIZED_KEYS" ]]; then
    install -oroot -m755 "$DROPBEAR_AUTHORIZED_KEYS" "/etc/dropbear-initramfs/authorized_keys"
fi

if [[ -n "$DROPBEAR_PORT" ]]; then
    sed -i 's/^#\?DROPBEAR_OPTIONS=.*/DROPBEAR_OPTIONS="-p '$DROPBEAR_PORT'"/' \
        /etc/dropbear-initramfs/config
fi

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
install -oroot -m755 "$INSTALL_SRC/files/initramfs/rpi-post-update-hook" \
    /etc/initramfs/post-update.d/90-rpi-boot-img

# install default boot files
[[ -n "$RPI_CONFIG_FILE" ]] || RPI_CONFIG_FILE="$INSTALL_SRC/files/boot/config.txt"
[[ -n "$RPI_CMDLINE_FILE" ]] || RPI_CMDLINE_FILE="$INSTALL_SRC/files/boot/cmdline.txt"
install -oroot -m755 "$RPI_CONFIG_FILE" "/etc/initramfs/rpi-config.txt"
install -oroot -m755 "$RPI_CMDLINE_FILE" "/etc/initramfs/rpi-cmdline.txt"

# save configuration vars
cat << EOF > /etc/initramfs/rpi-vars.sh
$([[ -z "$RPI_CMDLINE_EXTRA" ]] || declare -p RPI_CMDLINE_EXTRA)
$([[ -z "$RPI_FIRMWARE_FILES" ]] || declare -p RPI_FIRMWARE_FILES)
$([[ -z "$RPI_BOOT_EXTRA_FILES" ]] || declare -p RPI_BOOT_EXTRA_FILES)
$([[ -z "$RPI_CONFIG_EXTRA" ]] || declare -p RPI_CONFIG_EXTRA)
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

