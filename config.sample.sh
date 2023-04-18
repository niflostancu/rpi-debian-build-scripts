#!/bin/bash
# Local configuration file
# Rename to 'config.sh' for scripts to load it.

# Note: $SRC_DIR is available for building abs paths!

# Sudo-like utility to use (when root is required)
SUDO=sudo

# destination dirs (note: you need )
ROOTFS_DEST="/tmp/rpi-nas/rootfs/"
KERNEL_DEST="/tmp/rpi-nas/kernel-build/"

# cross compiler options
CROSS_COMPILER="aarch64-linux-gnu-"

# kernel compile options
KERNEL_MAKE_THREADS=8
# KERNEL_DEFCONFIG=interceptor_defconfig

# --------------------------------------------------
# RootFS provisioning options
# -----------------------------

# RPI Firmware files to copy to the boot ramdisk
RPI_FIRMWARE_FILES=(start4.elf fixup4.dat bcm2711-rpi-cm4.dtb)
#RPI_FIRMWARE_FILES+=(/boot/interceptor.dtb)
#RPI_CONFIG_FILE="$INSTALL_SRC/files/boot/config.txt"
#RPI_CMDLINE_FILE="$INSTALL_SRC/files/boot/cmdline.txt"
# Interceptor board example:
#RPI_CONFIG_EXTRA="device_tree=interceptor.dtb"

# extra packages to install
#EXTRA_PACKAGES=(firmware-realtek)

# extra .deb files to install
#EXTRA_DEBS=(swconfig-1.0.101-aarch64.deb)

# initramfs dropbear settings
#DROPBEAR_AUTHORIZED_KEYS="$SRC_DIR/dist/authorized_keys"
#DROPBEAR_PORT=2002

# Extra installation hook (to run custom scripts)
function custom_script() {
    #bash "$SRC_DIR/extra-interceptor/install.sh"
    true
}

