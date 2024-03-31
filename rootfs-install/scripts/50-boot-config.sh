#!/bin/bash
# Installs bootloader assets & configs

if [[ -n "$DISTRO_UPGRADE" ]]; then return 0; fi

mkdir -p /etc/initramfs

# install default boot files
RPI_CONFIG_FILE=${RPI_CONFIG_FILE:-"$INSTALL_SRC/files/boot/config.txt"}
RPI_RAW_CONFIG_FILE=${RPI_RAW_CONFIG_FILE:-"$INSTALL_SRC/files/boot/config-raw.txt"}
RPI_CMDLINE_FILE=${RPI_CMDLINE_FILE:-"$INSTALL_SRC/files/boot/cmdline.txt"}
install -oroot -m755 "$RPI_CONFIG_FILE" "/etc/initramfs/rpi-config.txt"
install -oroot -m755 "$RPI_RAW_CONFIG_FILE" "/etc/initramfs/rpi-config-raw.txt"
install -oroot -m755 "$RPI_CMDLINE_FILE" "/etc/initramfs/rpi-cmdline.txt"

# save configuration vars
cat << EOF > /etc/initramfs/rpi-vars.sh
$([[ -z "$RPI_DISABLE_FIRMWARE_GEN" ]] || declare -p RPI_DISABLE_FIRMWARE_GEN)
$([[ -z "$RPI_CMDLINE_EXTRA" ]] || declare -p RPI_CMDLINE_EXTRA)
$([[ -z "$IMAGE_ROOTFS_PART_NAME" ]] || declare -p IMAGE_ROOTFS_PART_NAME)
$([[ -z "$INITRAMFS_ROOT_DEVICE" ]] || declare -p INITRAMFS_ROOT_DEVICE)
$([[ -z "$RPI_FIRMWARE_FILES" ]] || declare -p RPI_FIRMWARE_FILES)
$([[ -z "$RPI_CONFIG_EXTRA" ]] || declare -p RPI_CONFIG_EXTRA)
$([[ -z "$RPI_BOOT_EXTRA_FILES" ]] || declare -p RPI_BOOT_EXTRA_FILES)
$([[ -z "$RPI_BOOT_RAMDISK_SIZE" ]] || declare -p RPI_BOOT_RAMDISK_SIZE)
$([[ -z "$RPI_SKIP_BOOT_CONFIG" ]] || declare -p RPI_SKIP_BOOT_CONFIG)
$([[ -z "$RPI_SKIP_BOOT_FIRMWARE" ]] || declare -p RPI_SKIP_BOOT_FIRMWARE)
$([[ -z "$RPI_SKIP_BOOT_RAMDISK" ]] || declare -p RPI_SKIP_BOOT_RAMDISK)
EOF

