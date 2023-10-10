#!/bin/bash
# Local configuration file
# Rename to 'config.sh' for scripts to load it.

# Note: $SRC_DIR is available for building abs paths!

# sudo-like utility to use (when root is required)
SUDO=sudo

# uncomment this if you want the Interceptor configuration preset
#IS_INTERCEPTOR=1

# destination dirs (note: you need ~5GB of free disk space in here)
BUILD_DEST=/tmp/rpi-debian
#ROOTFS_DEST="$BUILD_DEST/rootfs"
#KERNEL_DEST="$BUILD_DEST/kernel-build"
#UBOOT_DEST="$BUILD_DEST/u-boot"
#IMAGE_DEST="$BUILD_DEST/image.bin"

# cross compiler options
CROSS_COMPILER="aarch64-linux-gnu-"

# kernel compile options
KERNEL_MAKE_THREADS=4
KERNEL_DEFCONFIG=bcm2711_defconfig
#KERNEL_PATCHES_DIR="$SRC_DIR/dist/kernel-patches/"

# --------------------------------------------------
# RootFS provisioning options
# (those are mostly invoked inside a chroot)
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

# and now... the Interceptor board example preset:
if [[ "$IS_INTERCEPTOR" == "1" ]]; then
    KERNEL_PATCHES_DIR="$SRC_DIR/extra-interceptor/kernel-patches"

    # RPI boot files (will be copied by extra-interceptor/install.sh)
    RPI_FIRMWARE_FILES+=(/boot/interceptor.dtb)
    RPI_CONFIG_EXTRA="device_tree=interceptor.dtb"$'\n'

    # extra packages to install
    EXTRA_PACKAGES=(firmware-realtek)
    # extra .deb pkgs to install (must be manually placed in `dist/`)
    EXTRA_DEBS=(swconfig-1.0.101-aarch64.deb)

    # Extra installation hook (to run custom scripts)
    function custom_script() {
        bash "$SRC_DIR/extra-interceptor/install.sh"
    }
fi

