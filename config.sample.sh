#!/bin/bash
# Local configuration file
# Rename to 'config.sh' for scripts to load it.

# Sudo-like utility to use (when root is required)
SUDO=sudo

# destination dirs
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
# Interceptor board example:
#RPI_FIRMWARE_FILES+=(/boot/interceptor.dtb)
#RPI_CONFIG="device_tree=interceptor.dtb"

# extra packages to install
#EXTRA_PACKAGES=(firmware-realtek)

# extra .deb files to install
#EXTRA_DEBS=(swconfig-1.0.101-aarch64.deb)

# Extra installation hook (to run custom scripts)
function custom_script() {
    #bash "$SRC_DIR/extra-interceptor/install.sh"
    true
}

