#!/bin/bash
# Local configuration file (included in both host & rootfs execution contexts!)
# Rename to 'config.sh' for scripts to load it.
# Note: $SRC_DIR is available for building abs paths!

# sudo-like utility to use (when root is required)
SUDO=sudo

# uncomment this if you want a config overlay (e.g., custom boards)
#CUSTOM_CONFIG=${CUSTOM_CONFIG:-"vanilla-rpi"}
# when a custom config is used, compute its path
CUSTOM_CONFIG_DIR="$SRC_DIR/configs/$CUSTOM_CONFIG"

# destination dirs (note: you need ~5GB of free disk space in here)
BUILD_DEST=/tmp/rpi-debian${CUSTOM_CONFIG:+-${CUSTOM_CONFIG}}
#ROOTFS_DEST="$BUILD_DEST/rootfs"
#KERNEL_DEST="$BUILD_DEST/kernel-build"
#UBOOT_DEST="$BUILD_DEST/u-boot"
#IMAGE_DEST="$BUILD_DEST/image.bin"

# cross compiler options
CROSS_COMPILER="aarch64-linux-gnu-"

# kernel compilation options
KERNEL_MAKE_THREADS=4
KERNEL_DEFCONFIG=bcm2711_defconfig
#KERNEL_PATCHES_DIR="$CUSTOM_CONFIG_DIR/kernel-5.15"

# --------------------------------------------------
# RootFS provisioning options
# (those are mostly used inside a chroot context)
# -----------------------------
# RPI Firmware files to copy to the boot ramdisk (note: bash array!)
RPI_FIRMWARE_FILES=(start4.elf fixup4.dat bcm2711-rpi-cm4.dtb)
# RPI config.txt and cmdline.txt to install
# Afterwards, you can find / edit them inside /etc/initramfs/ on the rootfs ;)
RPI_CONFIG_FILE="$INSTALL_SRC/files/boot/config.txt"
RPI_CMDLINE_FILE="$INSTALL_SRC/files/boot/cmdline.txt"
# uncomment if using LUKS:
#RPI_CMDLINE_FILE="$INSTALL_SRC/files/boot/cmdline-cryptroot.txt"
# Append extra lines to config.txt:
#RPI_CONFIG_EXTRA="dtoverlay=vc4-kms-v3d"$'\n'

# main user to create (it will have an empty password initially!)
MAIN_USER=pi

# initramfs dropbear settings
DROPBEAR_AUTHORIZED_KEYS="$SRC_DIR/dist/authorized_keys"
DROPBEAR_PORT=2002

# include custom config file (if specified)
[[ -z "$CUSTOM_CONFIG" ]] || source "$CUSTOM_CONFIG_DIR/config.inc.sh"

