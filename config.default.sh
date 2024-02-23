#!/bin/bash
# Default configuration file (included in both host & rootfs execution contexts!).
# Copy / create 'config.sh' to customize it!
# Note: $SRC_DIR is available for building abs paths!

# uncomment if you want a configuration overlay (e.g., custom boards)
#CUSTOM_CONFIG=${CUSTOM_CONFIG:-"vanilla-rpi4"}

# --------------------------------------------------
# Host build options
# -----------------------------
# cross compiler options
CROSS_COMPILER=${CROSS_COMPILER:-"aarch64-linux-gnu-"}
# sudo-like utility to use (when root privileges are required)
SUDO=${SUDO:-sudo}

# distro build / config suffix
[[ -n "$DISTRO_SUFFIX" ]] || DISTRO_SUFFIX="${CUSTOM_CONFIG:+-${CUSTOM_CONFIG}}"
# destination dirs (note: you need ~5GB of free disk space in here)
BUILD_DEST=${BUILD_DEST:-"/tmp/rpi-debian$DISTRO_SUFFIX"}
# Note: you can leave those as they are automatically derived from BUILD_DEST
ROOTFS_DEST=${ROOTFS_DEST:-"$BUILD_DEST/rootfs"}
KERNEL_DEST=${KERNEL_DEST-"$BUILD_DEST/kernel-build"}
UBOOT_DEST=${UBOOT_DEST:-"$BUILD_DEST/u-boot"}
IMAGE_DEST=${IMAGE_DEST:-"$BUILD_DEST/image.bin"}

# --------------------------------------------------
# U-Boot build options
# -----------------------------

UBOOT_GIT=${UBOOT_GIT:-"https://github.com/u-boot/u-boot.git"}
UBOOT_BRANCH=${UBOOT_BRANCH:-"v2023.07.02"}
UBOOT_DEFCONFIG=${UBOOT_DEFCONFIG:-"rpi_4_defconfig"}
UBOOT_MAKE_THREADS=${UBOOT_MAKE_THREADS:-4}

# --------------------------------------------------
# Kernel build options
# -----------------------------

KERNEL_MAKE_THREADS=${KERNEL_MAKE_THREADS:-4}
# Note: you can override any of the CUSTOM_CONFIG parameters
#KERNEL_BRANCH=${KERNEL_BRANCH:-"rpi-6.1.y"}
#KERNEL_ARCH=${KERNEL_ARCH:-"arm64"}
#KERNEL_DEFCONFIG=${KERNEL_DEFCONFIG:-bcm2711_defconfig}
#KERNEL_DEFCONFIG="$SRC_DIR/dist/my-kernel_defconfig"
#KERNEL_PATCHES_DIR="$CUSTOM_CONFIG_DIR/kernel-5.15"
#KERNEL_LOCALVERSION=${KERNEL_LOCALVERSION:-'-rpi'}

# directory to be used for distributing built kernel files
KERNEL_DISTRIB_DIR=${KERNEL_DISTRIB_DIR:-"$SRC_DIR/dist/kernel$DISTRO_SUFFIX"}

# --------------------------------------------------
# RootFS provisioning options
# (those are mostly used inside a chroot context)
# -----------------------------

# RPI Firmware files to copy to the boot ramdisk (note: bash array!)
[[ -v RPI_FIRMWARE_FILES[@] ]] || \
    RPI_FIRMWARE_FILES=(start4.elf fixup4.dat bcm2711-rpi-cm4.dtb)
# Initial RPI config.txt and cmdline.txt to copy
# Afterwards, you can find / edit them inside /etc/initramfs/ on the rootfs ;)
RPI_CONFIG_FILE=${RPI_CONFIG_FILE:-"$INSTALL_SRC/files/boot/config.txt"}
RPI_CMDLINE_FILE=${RPI_CMDLINE_FILE:-"$INSTALL_SRC/files/boot/cmdline.txt"}
# e.g., if using LUKS:
#RPI_CMDLINE_FILE="$INSTALL_SRC/files/boot/cmdline-cryptroot.txt"
# use to append extra lines to config.txt:
#RPI_CONFIG_EXTRA="dtoverlay=vc4-kms-v3d"$'\n'
# Path to the mounted RPI firmware
RPI_FIRMWARE_DIR=${RPI_FIRMWARE_DIR:-"/boot/firmware"}

# initramfs scripts configuration (`54-initramfs.sh`)
#SKIP_INITRAMFS=
#INITRAMFS_CRYPTROOT=0
#INITRAMFS_DROPBEAR=0
#RPI_BOOT_RAMDISK_SIZE=32
# kernel installation options (see `57-kernel.sh`)
#SKIP_KERNEL=
#KERNEL_FROM_REPO=auto
#KERNEL_FROM_DEBS=auto
#INSTALL_KERNEL_PACKAGES=(linux-image-arm64 linux-headers-arm64)

# initramfs dropbear settings
DROPBEAR_AUTHORIZED_KEYS=${DROPBEAR_AUTHORIZED_KEYS:-"$SRC_DIR/dist/authorized_keys"}
DROPBEAR_PORT=${DROPBEAR_PORT:-2002}

# main user to create (it will have an empty password initially!)
MAIN_USER=${MAIN_USER:-pi}

# --------------------------------------------------
# Image build options
# -----------------------------

IMAGE_SIZE_MB=${IMAGE_SIZE_MB:-"2048"}
IMAGE_BOOT_PART_MB=${IMAGE_BOOT_PART_MB:-"100"}
IMAGE_ROOTFS_PART_NAME=${IMAGE_ROOTFS_PART_NAME:-"RPI_ROOTFS"}
IMAGE_BOOT_PART_NAME=${IMAGE_BOOT_PART_NAME:-"RPI_BOOT"}

INITRAMFS_ROOT_DEVICE=${IMAGE_ROOTFS_DEVICE:-"LABEL=$IMAGE_ROOTFS_PART_NAME"}

