#!/bin/bash
# Installs bootloader / kernel files & configs

if [[ "$SKIP_BOOT_FILES" =~ ^1|y(es)?$ ]]; then return 0; fi

apt_install initramfs-tools cryptsetup console-setup dropbear-initramfs \
    cryptsetup-initramfs

# boot-related configuration files
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

# first, install initramfs generation hooks to generate boot.img
# https://kernel-team.pages.debian.net/kernel-handbook/ch-update-hooks.html
install -oroot -m755 -d /etc/initramfs/post-update.d/
install -oroot -m755 "$INSTALL_SRC/files/initramfs/rpi-post-update-hook" \
    /etc/initramfs/post-update.d/90-rpi-boot-img

# install default boot files
RPI_CONFIG_FILE=${RPI_CONFIG_FILE:-"$INSTALL_SRC/files/boot/config.txt"}
RPI_RAW_CONFIG_FILE=${RPI_RAW_CONFIG_FILE:-"$INSTALL_SRC/files/boot/config-raw.txt"}
RPI_CMDLINE_FILE=${RPI_CMDLINE_FILE:-"$INSTALL_SRC/files/boot/cmdline.txt"}
install -oroot -m755 "$RPI_CONFIG_FILE" "/etc/initramfs/rpi-config.txt"
install -oroot -m755 "$RPI_RAW_CONFIG_FILE" "/etc/initramfs/rpi-config-raw.txt"
install -oroot -m755 "$RPI_CMDLINE_FILE" "/etc/initramfs/rpi-cmdline.txt"

# save configuration vars
cat << EOF > /etc/initramfs/rpi-vars.sh
$([[ -z "$RPI_CMDLINE_EXTRA" ]] || declare -p RPI_CMDLINE_EXTRA)
$([[ -z "$IMAGE_ROOTFS_PART_NAME" ]] || declare -p IMAGE_ROOTFS_PART_NAME)
$([[ -z "$RPI_FIRMWARE_FILES" ]] || declare -p RPI_FIRMWARE_FILES)
$([[ -z "$RPI_BOOT_EXTRA_FILES" ]] || declare -p RPI_BOOT_EXTRA_FILES)
$([[ -z "$RPI_CONFIG_EXTRA" ]] || declare -p RPI_CONFIG_EXTRA)
$([[ -z "$RPI_SKIP_IMAGE_GEN" ]] || declare -p RPI_SKIP_IMAGE_GEN)
EOF

# debs to install
KERNEL_PKG_PREFIXES=(linux-image- linux-headers-)
KERNEL_FILE="$(shopt -s nullglob; cd "$KERNEL_DISTRIB_DIR/"; files=( "${KERNEL_PKG_PREFIXES[0]}"*.deb ); echo "$files")"
if [[ -z "$KERNEL_FILE" || ! -f "$KERNEL_DISTRIB_DIR/$KERNEL_FILE" ]]; then
    log_error "Unable to find kernel .debs inside $KERNEL_DISTRIB_DIR!"
    return 0
fi

# [Re]Install kernel package (initramfs will be generated and hooks run)
(
    cd "$KERNEL_DISTRIB_DIR/"
    KERNEL_FILES=()
    for prefix in "${KERNEL_PKG_PREFIXES[@]}"; do
        _FIND_ARGS=(-name "$prefix*" -not -iname '*-dbg_*')
        _KERNEL_FILE=$( find . "${_FIND_ARGS[@]}" | sort -r --version-sort | head -1 )
        if [[ -z "$_KERNEL_FILE" ]]; then
            log_error "Coult not find package for $prefix !"
        fi
        KERNEL_FILES+=("$_KERNEL_FILE")
    done
    log_debug dpkg -i "${KERNEL_FILES[@]}"
    dpkg -i "${KERNEL_FILES[@]}"
)

